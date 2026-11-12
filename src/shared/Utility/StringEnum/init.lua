--!strict
local StringEnum = {}

-- Says whether a value is one of an enum module's string constants. Values that cross the network
-- are untrusted, so the enum can be any table of named strings, and the value can be anything.
function StringEnum.Contains(enum: any, value: any): boolean
    if typeof(value) ~= "string" then
        return false
    end

    for _, member in enum do
        if member == value then
            return true
        end
    end
    return false
end

table.freeze(StringEnum)
return StringEnum
