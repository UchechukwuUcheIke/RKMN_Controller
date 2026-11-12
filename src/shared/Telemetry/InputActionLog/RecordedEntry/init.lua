--!strict
local RecordedEntry = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local InputPhase = require(script.Parent.InputPhase)

type InputPhase = InputPhase.InputPhase

export type RecordedEntry = {
    Action: InputAction.ActionID,
    Phase: InputPhase,
    Time: number
}

function RecordedEntry.new(action: InputAction.ActionID, phase: InputPhase, clock: number?): RecordedEntry
    local currentTime = clock or os.clock()
    return table.freeze({
        Action = action,
        Phase = phase,
        Time = currentTime,
    })
end

table.freeze(RecordedEntry)
return RecordedEntry
