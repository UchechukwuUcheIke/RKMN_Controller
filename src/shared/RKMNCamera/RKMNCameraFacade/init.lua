--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local CameraZoneTracker = require(RKMNCameraFolder.CameraZoneTracker)
local CameraTargetSmoother = require(RKMNCameraFolder.CameraTargetSmoother)
local CameraTargetSolver = require(RKMNCameraFolder.CameraTargetSolver)
local CameraZone = require(RKMNCameraFolder.Data.CameraZone)

type CameraZoneTracker = CameraZoneTracker.CameraZoneTracker
type Connection = CameraZoneTracker.Connection
type CameraTargetSmoother = CameraTargetSmoother.CameraTargetSmoother
type CameraZone = CameraZone.CameraZone
type ViewParams = CameraTargetSolver.ViewParams
type CameraState = CameraTargetSolver.CameraState

local RKMNCameraFacade = {}
RKMNCameraFacade.__index = RKMNCameraFacade

type RKMNCameraFacadeData = {
    CameraZoneTracker: CameraZoneTracker,
    Smoother: CameraTargetSmoother,

    _camera: Camera,
    _isActive: boolean,
    _playerTarget: Model?,
    _cameraState: CameraState?,
    _viewParams: ViewParams,
    _zoneChangedConnection: Connection,
}

type RKMNCameraFacadePrototype = typeof(RKMNCameraFacade)

export type RKMNCameraFacade = typeof(setmetatable(
    {} :: RKMNCameraFacadeData,
    {} :: RKMNCameraFacadePrototype
))

function RKMNCameraFacade.new(camera: Camera, CameraZoneTracker: CameraZoneTracker, smoother: CameraTargetSmoother): RKMNCameraFacade
    local viewportSize = camera.ViewportSize
    local viewParams = {
        VerticalFieldOfView = camera.FieldOfView,
        Aspect = viewportSize.X / math.max(viewportSize.Y, 1),
    }
    
    local self = {
        CameraZoneTracker = CameraZoneTracker,
        Smoother = smoother,

        _camera = camera,
        _viewParams = viewParams,
        _isActive = false,
        _playerTarget = nil,
        _cameraState = nil,
    } :: RKMNCameraFacadeData

    setmetatable(self, RKMNCameraFacade)

    self._zoneChangedConnection = CameraZoneTracker:OnZoneChanged(function()
        self:_handleOnZoneChanged()
    end)

    return self
end

function RKMNCameraFacade._handleOnZoneChanged(self: RKMNCameraFacade): ()
    self._cameraState = nil
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

    self._cameraState = nil
    self._camera.CameraType = Enum.CameraType.Scriptable
    self.Smoother:SnapTo(self._camera.CFrame)
end

function RKMNCameraFacade.Disable(self: RKMNCameraFacade): ()
    if not self:IsActive() then
        return
    end
    self._isActive = false

    self._camera.CameraType = Enum.CameraType.Custom
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

function RKMNCameraFacade.GetViewParams(self: RKMNCameraFacade): ViewParams
    return self._viewParams
end

-- NOTE: Camera has its own grounded check, but should ideally use RKMNController's Grounded logic
function RKMNCameraFacade._isPlayerGrounded(self: RKMNCameraFacade): boolean
    local playerTarget = self._playerTarget
    local humanoid = playerTarget and playerTarget:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    return humanoid.FloorMaterial ~= Enum.Material.Air
end

function RKMNCameraFacade._getActiveZone(self: RKMNCameraFacade): CameraZone?
    local activeZoneId: string? = self.CameraZoneTracker:GetActiveCameraZoneId()
    if not activeZoneId then
        return nil
    end

    return self.CameraZoneTracker:GetCameraZone(activeZoneId)
end

function RKMNCameraFacade.Step(self: RKMNCameraFacade, dt: number): ()
    local playerCFrame: CFrame? = self:_getPlayerCFrame()
    if not playerCFrame then
        return
    end

    self.CameraZoneTracker:Update(playerCFrame.Position)

    local targetCFrame, nextState = CameraTargetSolver.Solve(
        playerCFrame,
        self:_getActiveZone(),
        self:GetViewParams(),
        self._cameraState,
        self:_isPlayerGrounded(),
        dt
    )
    self._cameraState = nextState

    self.Smoother:SetTarget(targetCFrame)
    self._camera.CFrame = self.Smoother:Update(dt)
end

function RKMNCameraFacade.Destroy(self: RKMNCameraFacade): ()
    self:Disable()
    self._zoneChangedConnection:Disconnect()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

return RKMNCameraFacade
