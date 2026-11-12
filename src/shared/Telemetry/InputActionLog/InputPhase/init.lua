--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringEnum = require(ReplicatedStorage.Utility.StringEnum)

export type InputPhase = "began" | "ended"

local InputPhase = {
    Began = "began" :: InputPhase,
    Ended = "ended" :: InputPhase,
}

function InputPhase.IsValid(value: any): boolean
    return StringEnum.Contains(InputPhase, value)
end

table.freeze(InputPhase)
return InputPhase
