--!strict
local InputActionLogEntry = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local InputPhase = require(script.Parent.InputPhase)

type InputPhase = InputPhase.InputPhase

export type InputActionLogEntry = {
    Action: InputAction.ActionID,
    Phase: InputPhase,
    SecondsAgo: number
}

function InputActionLogEntry.new(action: InputAction.ActionID, phase: InputPhase, secondsAgo: number): InputActionLogEntry
    return table.freeze({
        Action = action,
        Phase = phase,
        SecondsAgo = secondsAgo,
    })
end

table.freeze(InputActionLogEntry)
return InputActionLogEntry
