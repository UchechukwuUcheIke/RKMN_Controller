--!strict

local InputController = {}
InputController.__index = InputController


local TimerUtilityModule = require(script.Parent.TimerUtility)

type InputControllerData = {
    Timers: TimerUtilityModule.TimerUtility,
    IsEnabled: boolean,
    
    MoveDirection: number,
    IsHoldingJump: boolean,
    IsHoldingDash: boolean,
    IsCharging: boolean,
    HasBufferedJump: boolean,

    _connections: {RBXScriptSignal}
}

export type InputController = typeof(setmetatable({} :: InputControllerData, InputController))

function InputController.new(Timers: TimerUtilityModule.TimerUtility): InputController
    local self = setmetatable({}, InputController)

    self.Timers = Timers
    self.IsEnabled = false
    self.MoveDirection = 0
    self.IsHoldingJump = false
    self.IsHoldingDash = false
    self.IsCharging = false
    self.HasBufferedJump = false
    self._connections = {}

    return self
end

return InputController