--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local RunServiceAdapter = require(ReplicatedStorage.RunServiceAdapter)
local RenderPriorities = require(ReplicatedStorage.RenderPriorities)
local CameraZone = require(RKMNCameraFolder.Data.CameraZone)
local CameraZoneTracker = require(RKMNCameraFolder.CameraZoneTracker)
local CameraTargetSmoother = require(RKMNCameraFolder.CameraTargetSmoother)
local RKMNCameraFacade = require(RKMNCameraFolder.RKMNCameraFacade)

type CameraZone = CameraZone.CameraZone
type RKMNCameraFacade = RKMNCameraFacade.RKMNCameraFacade

local RKMNCameraSetup = {}

local DEFAULT_ZONE_ID = "Default"
local DEFAULT_ZONE_SIZE = Vector3.new(100000, 100000, 100000)
local DEFAULT_CAMERA_OFFSET = Vector3.new(0, 4, 30)

-- NOTE: Stand-in until zones are parsed from the map: one huge rail zone that covers everything.
local function makeDefaultZones(): { [string]: CameraZone }
    local defaultZone = CameraZone.createRail(DEFAULT_ZONE_ID, Vector3.zero, DEFAULT_ZONE_SIZE, DEFAULT_CAMERA_OFFSET)
    return { [defaultZone.Id] = defaultZone }
end

function RKMNCameraSetup.Setup(camera: Camera): RKMNCameraFacade
    local tracker = CameraZoneTracker.new()
    local zones = makeDefaultZones()
    tracker:SetZones(zones)

    local smoother = CameraTargetSmoother.new()
    local facade = RKMNCameraFacade.new(camera, tracker, smoother)

    local runServiceAdapter = RunServiceAdapter.new("RKMNCamera", RenderPriorities.Camera, function(dt: number)
        facade:Step(dt)
    end)

    facade:Enable()
    runServiceAdapter:Start()

    return facade
end

return RKMNCameraSetup
