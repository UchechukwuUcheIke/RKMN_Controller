--!strict
local RecordedInputActionLogEntry = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local InputPhase = require(script.Parent.InputPhase)

type InputPhase = InputPhase.InputPhase
type ActionID = InputAction.ActionID

export type RecordedInputActionLogEntry = {
    Action: ActionID,
    Phase: InputPhase,
    Time: number
}

function RecordedInputActionLogEntry.new(action: InputAction.ActionID, phase: InputPhase, clock: number?): RecordedInputActionLogEntry
    local currentTime = clock or os.clock()
    return table.freeze({
        Action = action,
        Phase = phase,
        Time = currentTime,
    })
end

table.freeze(RecordedInputActionLogEntry)
return RecordedInputActionLogEntry
