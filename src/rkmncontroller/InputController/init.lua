--!strict
local InputController = {}
InputController.__index = InputController

local RootDirectory = script.Parent
local UserInputService = game:GetService("UserInputService")
local Signal = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("goodsignal"))
local TimerUtilityModule = require(RootDirectory.TimerUtility)
local KEY_BINDINGS = require(RootDirectory.KeyBindings)
local TIMERS = require(RootDirectory.TimerIDRegistry)

type Signal = typeof(Signal)

type InputControllerData = {
    Timer: TimerUtilityModule.TimerUtility,
    IsEnabled: boolean,
    
    MoveDirection: number,
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
    self.MoveDirection = 0
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



function InputController:_isActionHeld(actionKeys: {Enum.KeyCode}): boolean
    for _, keycode: Enum.KeyCode in ipairs(actionKeys) do
		if UserInputService:IsKeyDown(keycode) then
			return true
		end
	end
	return false
end

function InputController:_handleJumpInput(): ()
    self.OnJumpPressed:Fire()
	self.HasBufferedJump = true
	self.Timer:StartTimer(TIMERS.JumpBuffer, 0.1)
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

function InputController:_resolveMoveDirection(): ()
    local leftHeld = self:_isActionHeld(KEY_BINDINGS.Left)
    local rightHeld = self:_isActionHeld(KEY_BINDINGS.Right)

    if leftHeld and rightHeld then
        self.MoveDirection = 0
    elseif leftHeld then
        self.MoveDirection = -1
    elseif rightHeld then
        self.MoveDirection = 1
    else
        self.MoveDirection = 0
    end
end

function InputController:Poll(dt: number): ()
    if not self.IsEnabled then
        return
    end

    if (self.HasBufferedJump and self.Timer.IsCompleted(TIMERS.JumpBuffer)) then
        self.HasBufferedJump = false
    end

    self:_resolveMoveDirection()

    print(KEY_BINDINGS.Jump)
    self.IsHoldingJump = self:_isActionHeld(KEY_BINDINGS.Jump)
    self.IsHoldingDash = self:_isActionHeld(KEY_BINDINGS.Dash)
    self.IsCharging = self:_isActionHeld(KEY_BINDINGS.Shoot)
end

function InputController:ConsumeJumpBuffer(): ()
    self.HasBufferedJump = false
    self.Timer:Cancel(TIMERS.JumpBuffer)
end

function InputController:FlushActiveInputs(): ()
    self.MoveDirection = 0
    self.IsHoldingJump = false
    self.IsCharging = false
    self.IsHoldingDash = false
    self:ConsumeJumpBuffer()
end

function InputController:SetEnabled(isEnabled: boolean)
    self.IsEnabled = isEnabled
    if not isEnabled then
        self:FlushActiveInputs()
    end
end

function InputController:Destroy(): ()
    for _, connection: RBXScriptConnection in ipairs(self._connections) do
        connection:Disconnect()
    end

    table.clear(self._connections)
    table.clear(self)    
    table.freeze(self)
end

return InputController