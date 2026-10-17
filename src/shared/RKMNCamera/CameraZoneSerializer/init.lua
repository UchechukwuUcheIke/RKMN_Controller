--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local DataFolder = RKMNCameraFolder.Data
local CameraZone = require(DataFolder.CameraZone)
local CameraZoneType = require(DataFolder.CameraZoneType)
local VerticalFollow = require(DataFolder.VerticalFollow)
local CameraZoneRecord = require(DataFolder.CameraZoneRecord)
local JSONUtils = require(ReplicatedStorage.JSONUtils)

type CameraZone = CameraZone.CameraZone
type CameraZoneRecord = CameraZoneRecord.CameraZoneRecord
type CameraZoneRecordDocument = CameraZoneRecord.CameraZoneRecordDocument

local FOCUS_POINT_NAME = "FocusPoint"

local CameraZoneSerializer = {}

local function isVerticalFollow(value: any): boolean
	for _, mode in VerticalFollow do
		local isAString = type(mode) == "string"
		if isAString and mode == value then
			return true
		end
	end
	return false
end

local function getOptionalAttribute(part: BasePart, name: string, expectedType: string): any?
	local value = part:GetAttribute(name)
	if value == nil then
		return nil
	end

	assert(typeof(value) == expectedType, `Zone {part.Name}: attribute {name} must be a {expectedType}`)
	return value
end

local function getRequiredAttribute(part: BasePart, name: string, expectedType: string): any
	local value = getOptionalAttribute(part, name, expectedType)
	assert(value ~= nil, `Zone {part.Name}: missing {expectedType} attribute {name}`)
	return value
end

local function getZoneType(part: BasePart): string
	local zoneType = getOptionalAttribute(part, "ZoneType", "string") or CameraZoneType.Rail
	assert(
		zoneType == CameraZoneType.Rail or zoneType == CameraZoneType.Locked,
		`Zone {part.Name}: unknown ZoneType {zoneType}`
	)
	return zoneType
end

local function getVerticalFollow(part: BasePart): string?
	local verticalFollow = getOptionalAttribute(part, "VerticalFollow", "string")
	if verticalFollow == nil then
		return nil
	end

	assert(isVerticalFollow(verticalFollow), `Zone {part.Name}: unknown VerticalFollow {verticalFollow}`)

	return verticalFollow
end

local function readRailFields(part: BasePart, record: CameraZoneRecord): ()
	local cameraOffset: Vector3 = getRequiredAttribute(part, "CameraOffset", "Vector3")
	record.CameraOffset = JSONUtils.vector3ToArray(cameraOffset)
	record.VerticalFollow = getVerticalFollow(part)
	record.DeadzoneFraction = getOptionalAttribute(part, "DeadzoneFraction", "number")
	record.GroundedScrollSpeed = getOptionalAttribute(part, "GroundedScrollSpeed", "number")
end

local function readLockedFields(part: BasePart, record: CameraZoneRecord): ()
	local focusPoint = part:FindFirstChild(FOCUS_POINT_NAME)
	assert(
		focusPoint and focusPoint:IsA("Attachment"),
		`Zone {part.Name}: Locked zones need an Attachment child named {FOCUS_POINT_NAME}`
	)
	record.FocusCFrame = JSONUtils.cframeToArray((focusPoint :: Attachment).WorldCFrame)
end

local function readZone(part: BasePart): CameraZoneRecord
	local zoneType = getZoneType(part)
	local record: CameraZoneRecord = {
		Id = part.Name,
		Type = zoneType,
		Center = JSONUtils.vector3ToArray(part.Position),
		Size = JSONUtils.vector3ToArray(part.Size),
	}

	if zoneType == CameraZoneType.Locked then
		readLockedFields(part, record)
	else
		readRailFields(part, record)
	end

	return record
end

function CameraZoneSerializer.SerializeFolder(zonesFolder: Instance): string
	local records: { CameraZoneRecord } = {}
	local seenIds: { [string]: boolean } = {}

	for _, child in zonesFolder:GetChildren() do
		if not child:IsA("BasePart") then
			continue
		end

		assert(not seenIds[child.Name], `Duplicate camera zone name: {child.Name}`)
		seenIds[child.Name] = true
		table.insert(records, readZone(child))
	end

	-- Sorted so re-running the plugin produces a stable result.
	table.sort(records, function(a: CameraZoneRecord, b: CameraZoneRecord)
		return a.Id < b.Id
	end)

	local document: CameraZoneRecordDocument = {
		Version = CameraZoneRecord.SCHEMA_VERSION,
		CameraZones = records,
	}

	return HttpService:JSONEncode(document)
end

local function readOptionalVerticalFollow(record: any, label: string): string?
	local value = record.VerticalFollow
	if value == nil then
		return nil
	end

	assert(isVerticalFollow(value), `{label}: unknown VerticalFollow {value}`)
	return value
end

local function deserializeRail(id: string, center: Vector3, size: Vector3, record: any, label: string): CameraZone
	local cameraOffset = JSONUtils.arrayToVector3(record.CameraOffset, `{label}: CameraOffset`)

	return CameraZone.createRail(id, center, size, cameraOffset, {
		VerticalFollow = readOptionalVerticalFollow(record, label) :: any,
		DeadzoneFraction = JSONUtils.readOptionalNumber(record, "DeadzoneFraction", label),
		GroundedScrollSpeed = JSONUtils.readOptionalNumber(record, "GroundedScrollSpeed", label),
	})
end

local function deserializeLocked(id: string, center: Vector3, size: Vector3, record: any, label: string): CameraZone
	local focusCFrame = JSONUtils.arrayToCFrame(record.FocusCFrame, `{label}: FocusCFrame`)
	return CameraZone.createLocked(id, center, size, focusCFrame)
end

local function deserializeZone(record: any, index: number): CameraZone
	assert(type(record) == "table", `Zone #{index} must be an object`)
	assert(type(record.Id) == "string", `Zone #{index}: Id must be a string`)

	local id: string = record.Id
	local label = `Zone {id}`
	local center = JSONUtils.arrayToVector3(record.Center, `{label}: Center`)
	local size = JSONUtils.arrayToVector3(record.Size, `{label}: Size`)

	if record.Type == CameraZoneType.Locked then
		return deserializeLocked(id, center, size, record, label)
	elseif record.Type == CameraZoneType.Rail then
		return deserializeRail(id, center, size, record, label)
	end

	error(`{label}: unknown Type {record.Type}`)
end

function CameraZoneSerializer.Deserialize(json: string): { [string]: CameraZone }
	local document: any = HttpService:JSONDecode(json)
	assert(type(document) == "table", "Camera zone JSON must be an object")
	assert(
		document.Version == CameraZoneRecord.SCHEMA_VERSION,
		`Unsupported camera zone schema version {document.Version}, expected {CameraZoneRecord.SCHEMA_VERSION}`
	)
	assert(type(document.Zones) == "table", "Camera zone JSON is missing its Zones array")

	local zones: { [string]: CameraZone } = {}
	for index, record in document.Zones do
		local zone = deserializeZone(record, index)
		assert(zones[zone.Id] == nil, `Duplicate camera zone id: {zone.Id}`)
		zones[zone.Id] = zone
	end

	return zones
end

return CameraZoneSerializer
