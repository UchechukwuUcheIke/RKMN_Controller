--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringEnum = require(ReplicatedStorage.Utility.StringEnum)

export type Platform = "mobile" | "pc" | "console" | "unknown"

local Platform = {
    Mobile = "mobile" :: Platform,
    PC = "pc" :: Platform,
    Console = "console" :: Platform,
    Unknown = "unknown" :: Platform,
}

function Platform.IsValid(value: any): boolean
    return StringEnum.Contains(Platform, value)
end

table.freeze(Platform)
return Platform
