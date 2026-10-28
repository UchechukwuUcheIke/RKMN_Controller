--!strict
local PlayerInputFacade = {}
PlayerInputFacade.__index = PlayerInputFacade

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerInputFolder = script.Parent
local Signal = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("goodsignal"))

local Direction = require(ReplicatedStorage.Data.Direction)
local Timers = require(ReplicatedStorage.RKMNController.TimerIDRegistry)
local TimerUtility = require(ReplicatedStorage.RKMNController.TimerUtility)
local InputAction = require(PlayerInputFolder.InputAction)

local InputMapper = require(PlayerInputFolder.InputMapper)
local RawInputObserver = require(PlayerInputFolder.RawInputObserver)
local InputBuffer = require(PlayerInputFolder.InputBuffer)
local DirectionResolver = require(PlayerInputFolder.DirectionResolver)

type Signal = typeof(Signal)
type Direction = Direction.Direction
type TimerUtility = TimerUtility.TimerUtility
type ActionID = InputAction.ActionID
type InputMapper = InputMapper.InputMapper
type InputBuffer = InputBuffer.InputBuffer
type DirectionResolver = DirectionResolver.DirectionResolver
type RawInputObserver = RawInputObserver.RawInputObserver
type Connection = { Disconnect: (self: any) -> () }

type PlayerInputFacadeData = {
    _rawInputObserver: RawInputObserver,
    _jumpBuffer: InputBuffer,
    _dashBuffer: InputBuffer,
    _directionResolver: DirectionResolver,

    _isEnabled: boolean,
    _isTriggerHeld: boolean,

    OnJumpPressed: Signal,
    OnDashPressed: Signal,
    OnTriggerPressed: Signal,
    OnTriggerReleased: Signal,

    _actionConnectionBegan: Connection,
    _actionConnectionEnded: Connection
}

export type PlayerInputFacade = typeof(setmetatable({} :: PlayerInputFacadeData, PlayerInputFacade))

local BUFFER_DURATION = 0.1

function PlayerInputFacade.new(timerUtility: TimerUtility, inputMapper: InputMapper): PlayerInputFacade
    local self = setmetatable({}, PlayerInputFacade)

    self._isEnabled = false
    self._isTriggerHeld = false

    self._rawInputObserver = RawInputObserver.new(inputMapper)
    self._jumpBuffer = InputBuffer.new(timerUtility, Timers.JumpBuffer, BUFFER_DURATION)
    self._dashBuffer = InputBuffer.new(timerUtility, Timers.DashBuffer, BUFFER_DURATION)
    self._directionResolver = DirectionResolver.new()

    self.OnJumpPressed = Signal.new()
    self.OnDashPressed = Signal.new()
    self.OnTriggerPressed = Signal.new()
    self.OnTriggerReleased = Signal.new()

    self._actionConnectionBegan = self._rawInputObserver.OnActionBegan:Connect(function(actionName: ActionID)
        self:_handleActionBegan(actionName)
    end)

    self._actionConnectionEnded = self._rawInputObserver.OnActionEnded:Connect(function(actionName: ActionID)
        self:_handleActionEnded(actionName)
    end)

    return self :: PlayerInputFacade
end

function PlayerInputFacade._handleActionBegan(self: PlayerInputFacade, actionName: ActionID): ()
    if not self._isEnabled then
        return
    end

    if actionName == InputAction.Jump then
        self._jumpBuffer:Fill()
        self.OnJumpPressed:Fire()
    elseif actionName == InputAction.Dash then
        self._dashBuffer:Fill()
        self.OnDashPressed:Fire()
    elseif actionName == InputAction.Shoot then
        self._isTriggerHeld = true
        self.OnTriggerPressed:Fire()
    end
end

-- Handled while disabled too, so a trigger pressed while enabled is always released.
function PlayerInputFacade._handleActionEnded(self: PlayerInputFacade, actionName: ActionID): ()
    if actionName == InputAction.Shoot then
        self:_releaseTrigger()
    end
end

function PlayerInputFacade._releaseTrigger(self: PlayerInputFacade): ()
    if not self._isTriggerHeld then
        return
    end

    self._isTriggerHeld = false
    self.OnTriggerReleased:Fire()
end

function PlayerInputFacade._resolveMovement(self: PlayerInputFacade): ()
    local isLeft = self._rawInputObserver:IsActionHeld(InputAction.Left)
    local isRight = self._rawInputObserver:IsActionHeld(InputAction.Right)
    self._directionResolver:Resolve(isLeft, isRight)
end

function PlayerInputFacade.Poll(self: PlayerInputFacade, _deltaTime: number): ()
    if not self._isEnabled then
        return
    end

    self:_resolveMovement()
end

function PlayerInputFacade.SetEnabled(self: PlayerInputFacade, isEnabled: boolean): ()
    self._isEnabled = isEnabled
    if isEnabled then
        return
    end

    self._jumpBuffer:Consume()
    self._dashBuffer:Consume()
    self._directionResolver:Resolve(false, false)
    self:_releaseTrigger()
end

function PlayerInputFacade.BindVirtualButton(self: PlayerInputFacade, actionName: ActionID, button: GuiButton): ()
    self._rawInputObserver:BindVirtualButton(actionName, button)
end

function PlayerInputFacade.ReleaseVirtualHolds(self: PlayerInputFacade): ()
    self._rawInputObserver:ReleaseAllVirtual()
end

function PlayerInputFacade.GetMoveDirection(self: PlayerInputFacade): Direction
    return self._directionResolver:GetDirection()
end

function PlayerInputFacade.HasBufferedJump(self: PlayerInputFacade): boolean
    return self._jumpBuffer:IsFilled()
end

function PlayerInputFacade.HasBufferedDash(self: PlayerInputFacade): boolean
    return self._dashBuffer:IsFilled()
end

function PlayerInputFacade.IsHoldingJump(self: PlayerInputFacade): boolean
    return self._isEnabled and self._rawInputObserver:IsActionHeld(InputAction.Jump)
end

function PlayerInputFacade.IsHoldingDash(self: PlayerInputFacade): boolean
    return self._isEnabled and self._rawInputObserver:IsActionHeld(InputAction.Dash)
end

function PlayerInputFacade.IsCharging(self: PlayerInputFacade): boolean
    return self._isEnabled and self._rawInputObserver:IsActionHeld(InputAction.Shoot)
end

function PlayerInputFacade.ConsumeJumpBuffer(self: PlayerInputFacade): ()
    self._jumpBuffer:Consume()
end

function PlayerInputFacade.ConsumeDashBuffer(self: PlayerInputFacade): ()
    self._dashBuffer:Consume()
end

function PlayerInputFacade.Destroy(self: PlayerInputFacade): ()
    self._actionConnectionBegan:Disconnect()
    self._actionConnectionEnded:Disconnect()
    self._rawInputObserver:Destroy()
    self._jumpBuffer:Destroy()
    self._dashBuffer:Destroy()
    self._directionResolver:Destroy()
    self.OnJumpPressed:DisconnectAll()
    self.OnDashPressed:DisconnectAll()
    self.OnTriggerPressed:DisconnectAll()
    self.OnTriggerReleased:DisconnectAll()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(PlayerInputFacade)
return PlayerInputFacade
