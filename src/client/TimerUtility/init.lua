--!strict

local TimerUtility = {}
TimerUtility.__index = TimerUtility

local Types = require(script.Parent.Types)

export type TimerUtility = typeof(setmetatable({} :: Types.TimerUtilityData, TimerUtility))

function TimerUtility.new(): TimerUtility
    local self = setmetatable({}, TimerUtility)

    return self
end

return TimerUtility