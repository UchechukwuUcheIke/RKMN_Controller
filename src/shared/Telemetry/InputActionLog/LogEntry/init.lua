--!strict
local LogEntry = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local InputPhase = require(script.Parent.InputPhase)

type InputPhase = InputPhase.InputPhase

export type LogEntry = {
    Action: InputAction.ActionID,
    Phase: InputPhase,
    SecondsAgo: number
}

function LogEntry.new(action: InputAction.ActionID, phase: InputPhase, secondsAgo: number): LogEntry
    return table.freeze({
        Action = action,
        Phase = phase,
        SecondsAgo = secondsAgo,
    })
end

table.freeze(LogEntry)
return LogEntry
