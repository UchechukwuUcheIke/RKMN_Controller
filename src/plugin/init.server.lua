--!nonstrict
-- Studio plugin: serializes the camera zone parts in the map into a StringValue the game can load.
-- Build with: rojo build plugin.project.json --plugin RKMNCameraZones.rbxm
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZONES_FOLDER_NAME = "CameraZones"
local OUTPUT_NAME = "CameraZonesJSON"

local toolbar = plugin:CreateToolbar("RKMN")
local button = toolbar:CreateButton("Serialize Camera Zones", `Serialize workspace.{ZONES_FOLDER_NAME} to JSON`, "")
button.ClickableWhenViewportHidden = true

local function getOrCreateOutput(): StringValue
	local existing = ReplicatedStorage:FindFirstChild(OUTPUT_NAME)
	if existing then
		assert(existing:IsA("StringValue"), `ReplicatedStorage.{OUTPUT_NAME} exists but is not a StringValue`)
		return existing
	end

	local output = Instance.new("StringValue")
	output.Name = OUTPUT_NAME
	output.Parent = ReplicatedStorage
	return output
end

local function serializeCameraZones()
	local zonesFolder = workspace:FindFirstChild(ZONES_FOLDER_NAME)
	assert(zonesFolder, `No {ZONES_FOLDER_NAME} folder found in Workspace`)

	local serializer = require(ReplicatedStorage.RKMNCamera.CameraZoneSerializer)
	local json = serializer.SerializeFolder(zonesFolder)

	local recording = ChangeHistoryService:TryBeginRecording("Serialize Camera Zones")
	getOrCreateOutput().Value = json
	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end

	print(`[RKMN] Serialized {#zonesFolder:GetChildren()} camera zone parts to ReplicatedStorage.{OUTPUT_NAME}`)
end

button.Click:Connect(function()
	local ok, err = pcall(serializeCameraZones)
	if not ok then
		warn(`[RKMN] Camera zone serialization failed: {err}`)
	end
end)
