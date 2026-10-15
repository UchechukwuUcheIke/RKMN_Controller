--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local CameraZoneTracker = require(RKMNCameraFolder.CameraZoneTracker)
local CameraSpring = require(RKMNCameraFolder.CameraSpring)
local CameraTargetSolver = require(RKMNCameraFolder.CameraTargetSolver)
local CameraZone = require(RKMNCameraFolder.Data.CameraZone)

type CameraZoneTracker = CameraZoneTracker.CameraZoneTracker
type CameraSpring = CameraSpring.CameraSpring
type CameraZone = CameraZone.CameraZone

local RKMNCameraFacade = {}
RKMNCameraFacade.__index = RKMNCameraFacade

type RKMNCameraFacadeData = {
    Tracker: CameraZoneTracker,
    Spring: CameraSpring,
    Camera: Camera,

    _isActive: boolean,
    _playerTarget: Model?,
}

type RKMNCameraFacadePrototype = typeof(RKMNCameraFacade)

export type RKMNCameraFacade = typeof(setmetatable(
    {} :: RKMNCameraFacadeData,
    {} :: RKMNCameraFacadePrototype
))

function RKMNCameraFacade.new(camera: Camera, tracker: CameraZoneTracker, spring: CameraSpring): RKMNCameraFacade
    local data = {  
        Tracker = tracker,
        Spring = spring,
        Camera = camera,

        _isActive = false,
        _playerTarget = nil,
    } :: RKMNCameraFacadeData

    return setmetatable(data, RKMNCameraFacade)
end

function RKMNCameraFacade.SetPlayerTarget(self: RKMNCameraFacade, characterModel: Model): ()
    self._playerTarget = characterModel
end

function RKMNCameraFacade.IsActive(self: RKMNCameraFacade): boolean
    return self._isActive
end

function RKMNCameraFacade.Enable(self: RKMNCameraFacade): ()
    if self:IsActive() then
        return
    end
    self._isActive = true

    self.Camera.CameraType = Enum.CameraType.Scriptable
    self.Spring:SnapTo(self.Camera.CFrame)
end

function RKMNCameraFacade.Disable(self: RKMNCameraFacade): ()
    if not self:IsActive() then
        return
    end
    self._isActive = false

    self.Camera.CameraType = Enum.CameraType.Custom
end

function RKMNCameraFacade._getPlayerCFrame(self: RKMNCameraFacade): CFrame?
    local playerTarget = self._playerTarget
    if not playerTarget then
        return nil
    end

    local rootPart = playerTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not rootPart then
        return nil
    end

    return rootPart.CFrame
end

function RKMNCameraFacade._getActiveZone(self: RKMNCameraFacade): CameraZone?
    local activeZoneId: string? = self.Tracker:GetActiveCameraZoneId()
    if not activeZoneId then
        return nil
    end

    return self.Tracker:GetCameraZone(activeZoneId)
end

function RKMNCameraFacade.Step(self: RKMNCameraFacade, dt: number): ()
    local playerCFrame: CFrame? = self:_getPlayerCFrame()
    if not playerCFrame then
        return
    end

    self.Tracker:Update(playerCFrame.Position)

    local zone: CameraZone? = self:_getActiveZone()
    self.Spring:SetTarget(CameraTargetSolver.Solve(playerCFrame, zone))
    self.Camera.CFrame = self.Spring:Update(dt)
end

function RKMNCameraFacade.Destroy(self: RKMNCameraFacade): ()
    self:Disable()
    setmetatable(self :: any, nil)
end

return RKMNCameraFacade
