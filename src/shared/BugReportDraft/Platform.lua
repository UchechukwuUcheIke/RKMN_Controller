--!strict
export type Platform = "mobile" | "pc" | "console" | "unknown"

local Platform = {
    Mobile = "mobile" :: Platform,
    PC = "pc" :: Platform,
    Console = "console" :: Platform,
    Unknown = "unknown" :: Platform,
}

local VALID_VALUES: {[string]: boolean} = {}
for _, value in Platform do
    VALID_VALUES[value] = true
end
table.freeze(VALID_VALUES)

function Platform.IsValid(value: any): boolean
    return typeof(value) == "string" and VALID_VALUES[value] == true
end

table.freeze(Platform)
return Platform
