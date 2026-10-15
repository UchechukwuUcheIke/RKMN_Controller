--!strict
local FlagStandService = game:GetService("FlagStandService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local DataFolder = RKMNCameraFolder.Data
local CameraZoneType = require(DataFolder.CameraZoneType)
local CameraZone = require(DataFolder.CameraZone)
local DevPackages = ReplicatedStorage.DevPackages
local Signal = require(DevPackages.goodsignal)

local CameraZoneTracker = {}
CameraZoneTracker.__index = CameraZoneTracker

type CameraZoneType = CameraZoneType.CameraZoneType
type SpatialBounds = CameraZone.SpatialBounds
type CameraZone = CameraZone.CameraZone
type Signal = typeof(Signal)

type CameraZoneTrackerData = {
	_activeCameraZoneId: string?,
	_zones: { [string]: CameraZone },
	_zoneChangedEvent: Signal,
}

type CameraZoneTrackerPrototype = typeof(CameraZoneTracker)

export type CameraZoneTracker = typeof(setmetatable(
	{} :: CameraZoneTrackerData,
	{} :: CameraZoneTrackerPrototype
))

local function checkPointInZone(point: Vector3, center: Vector3, size: Vector3): boolean
	local halfSize = size / 2
	local min = center - halfSize
	local max = center + halfSize

    local isInXAxis = point.X >= min.X and point.X <= max.X
    local isInYAxis = point.Y >= min.Y and point.Y <= max.Y
    local isInZAxis = point.Z >= min.Z and point.Z <= max.Z
    local isInZone = isInXAxis and isInYAxis and isInZAxis
	
	return isInZone
end

function CameraZoneTracker.new(): CameraZoneTracker
	local self = {
		_activeCameraZoneId = nil,
		_zones = {},
		_zoneChangedEvent = Signal.new(),
	} :: CameraZoneTrackerData
	
	return setmetatable(self, CameraZoneTracker)
end

function CameraZoneTracker.SetZones(self: CameraZoneTracker, parsedZones: { [string]: CameraZone }): ()
	self._zones = parsedZones
end

function CameraZoneTracker.GetActiveCameraZoneId(self: CameraZoneTracker): string?
    return self._activeCameraZoneId
end

function CameraZoneTracker.GetCameraZone(self: CameraZoneTracker, cameraZoneId: string): CameraZone?
    return self._zones[cameraZoneId]
end

function CameraZoneTracker._checkPointInActiveCameraZone(self: CameraZoneTracker, position: Vector3): boolean
    local activeCameraZoneId: string? = self:GetActiveCameraZoneId()
    if not activeCameraZoneId then
        return false
    end

    local activeZone: CameraZone? = self._zones[activeCameraZoneId]
    if not activeZone then
        return false
    end

    local zoneBounds: SpatialBounds = activeZone.SpatialBounds
    local center: Vector3 = zoneBounds.Center
    local size: Vector3 = zoneBounds.Size
    local isPointInZone = checkPointInZone(position, center, size)
    
    return isPointInZone
end

function CameraZoneTracker._findCameraZone(self: CameraZoneTracker, position: Vector3): CameraZone?
	local foundZoneData: CameraZone? = nil
	
	for id: string, zoneData: CameraZone in pairs(self._zones) do
        local zoneBounds: SpatialBounds = zoneData.SpatialBounds
        local center: Vector3 = zoneBounds.Center
        local size: Vector3 = zoneBounds.Size

		if checkPointInZone(position, center, size) then
			foundZoneData = zoneData
			break
		end
	end
	
    return foundZoneData
end

function CameraZoneTracker._attemptUpdateActiveCameraZoneId(self: CameraZoneTracker, cameraZone: CameraZone?): ()
    if not cameraZone then
        self._activeCameraZoneId = nil
        self._zoneChangedEvent:Fire(nil)
        return
    end

    local cameraZoneId = cameraZone.Id
	if cameraZoneId ~= self._activeCameraZoneId then
		self._activeCameraZoneId = cameraZoneId
		self._zoneChangedEvent:Fire(cameraZoneId)
	end
end

function CameraZoneTracker.Update(self: CameraZoneTracker, position: Vector3): ()
	if self:_checkPointInActiveCameraZone(position) then
        return
    end

	local foundCameraZone = self:_findCameraZone(position)
    self:_attemptUpdateActiveCameraZoneId(foundCameraZone)
end

function CameraZoneTracker.Destroy(self: CameraZoneTracker): ()
	self._zoneChangedEvent:Destroy()
	table.clear(self._zones)
	setmetatable(self :: any, nil)
end

return CameraZoneTracker

