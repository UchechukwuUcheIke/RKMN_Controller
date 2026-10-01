--!strict
local InputController = {}
InputController.__index = InputController

local RKMNControllerFolder = script.Parent
local UserInputService = game:GetService("UserInputService")
local Direction = require(RKMNControllerFolder.Direction)
local Signal = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("goodsignal"))
local TimerUtilityModule = require(RKMNControllerFolder.TimerUtility)
local KEY_BINDINGS = require(RKMNControllerFolder.KeyBindings)
local Timers = require(RKMNControllerFolder.TimerIDRegistry)

type Signal = typeof(Signal)
type Direction = Direction.Direction

type InputControllerData = {
    Timer: TimerUtilityModule.TimerUtility,
    IsEnabled: boolean,
    
    MoveDirection: Direction,
    IsHoldingJump: boolean,
    IsHoldingDash: boolean,
    IsCharging: boolean,
    HasBufferedJump: boolean,

    OnJumpPressed: Signal,
    OnDashPressed: Signal,
    OnShootBegan: Signal,
    OnShootEnded: Signal,

    _connections: {RBXScriptConnection},
    _bindEvents: any,
}

export type InputController = typeof(setmetatable({} :: InputControllerData, InputController))

function InputController.new(TimerUtility: TimerUtilityModule.TimerUtility): InputController
    local self = setmetatable({}, InputController)

    self.Timer = TimerUtility
    self.IsEnabled = false
    self.MoveDirection = Direction.None
    self.IsHoldingJump = false
    self.IsHoldingDash = false
    self.IsCharging = false
    self.HasBufferedJump = false

    self.OnJumpPressed = Signal.new()
    self.OnDashPressed = Signal.new()
    self.OnShootBegan = Signal.new()
    self.OnShootEnded = Signal.new()

    self._connections = {}

    return self :: InputController
end



local function isActionHeld(actionKeys: {Enum.KeyCode}): boolean
    for _, keycode: Enum.KeyCode in ipairs(actionKeys) do
		if UserInputService:IsKeyDown(keycode) then
			return true
		end
	end
	return false
end

function InputController._handleJumpInput(self: InputController): ()
    self.OnJumpPressed:Fire()
	self.HasBufferedJump = true
	self.Timer:StartTimer(Timers.JumpBuffer, 0.1)
end

function isBindingPressed(binding: {Enum.KeyCode}, keycode: Enum.KeyCode): boolean
    return table.find(binding, keycode) ~= nil
end

function InputController:_onInputBegan(input: InputObject, gameProcessed: boolean): ()
    if gameProcessed or not self.IsEnabled then 
        return 
    end

    -- TODO: This won't scale well. think of a cleaner way we can
    -- Handle ever increasing input cases
    if (isBindingPressed(KEY_BINDINGS.Jump, input.KeyCode)) then
        self:_handleJumpInput()

    elseif (isBindingPressed(KEY_BINDINGS.Dash, input.KeyCode)) then
        self.OnDashPressed:Fire()
    elseif (isBindingPressed(KEY_BINDINGS.Shoot, input.KeyCode)) then
        self.OnShootBegan:Fire()
    end
end

function InputController:_onInputEnded(input: InputObject, gameProcessed: boolean): ()
    if (isBindingPressed(KEY_BINDINGS.Shoot, input.KeyCode)) then
        self.OnShootEnded:Fire()
    end
end


function InputController:_bindEvents(): ()
    local onInputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        self:_onInputBegan(input, gameProcessed)
    end)
    table.insert(self._connections, onInputBeganConnection)

    local onInputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        self:_onInputEnded(input, gameProcessed)
    end)
    table.insert(self._connections, onInputEndedConnection)
end

function InputController._resolveMoveDirection(self: InputController): ()
    local leftHeld = isActionHeld(KEY_BINDINGS.Left)
    local rightHeld = isActionHeld(KEY_BINDINGS.Right)

    if leftHeld and rightHeld then
        self.MoveDirection = Direction.None
    elseif leftHeld then
        self.MoveDirection = Direction.Left
    elseif rightHeld then
        self.MoveDirection = Direction.Right
    else
        self.MoveDirection = Direction.None
    end
end

function InputController.Poll(self: InputController, dt: number): ()
    if not self.IsEnabled then
        return
    end

    if (self.HasBufferedJump and self.Timer.IsCompleted(Timers.JumpBuffer)) then
        self.HasBufferedJump = false
    end

    self:_resolveMoveDirection()

    print(KEY_BINDINGS.Jump)
    self.IsHoldingJump = isActionHeld(KEY_BINDINGS.Jump)
    self.IsHoldingDash = isActionHeld(KEY_BINDINGS.Dash)
    self.IsCharging = isActionHeld(KEY_BINDINGS.Shoot)
end

function InputController.ConsumeJumpBuffer(self: InputController): ()
    self.HasBufferedJump = false
    self.Timer:Cancel(Timers.JumpBuffer)
end

function InputController.FlushActiveInputs(self: InputController): ()
    self.MoveDirection = Direction.None
    self.IsHoldingJump = false
    self.IsCharging = false
    self.IsHoldingDash = false
    self:ConsumeJumpBuffer()
end

function InputController.SetEnabled(self: InputController, isEnabled: boolean)
    self.IsEnabled = isEnabled
    if not isEnabled then
        self:FlushActiveInputs()
    end
end

function InputController.Destroy(self: InputController): ()
    for _, connection: RBXScriptConnection in ipairs(self._connections) do
        connection:Disconnect()
    end

    table.clear(self._connections)    
    table.freeze(self)
end

table.freeze(InputController)

return InputController