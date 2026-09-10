--!strict

local UserInputService = game:GetService("UserInputService")

local TimerUtility = require(script.Parent.TimerUtility)

type TimerUtility = TimerUtility.TimerUtility

local InputController = {}
InputController.__index = InputController

type InputControllerData = {
    Timers: TimerUtility,
    IsEnabled: boolean,
    
    MoveDirection: number,
    IsHoldingJump: boolean,
    IsHoldingDash: boolean,
    IsCharging: boolean,
    HasBufferedJump: boolean,

    _connections: {RBXScriptSignal}
}

export type InputController = typeof(setmetatable({} :: InputControllerData, InputController))

return InputController