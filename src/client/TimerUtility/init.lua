--!strict

local TimerUtility = {}
TimerUtility.__index = TimerUtility

type TimerUtilityData = {

}

export type TimerUtility = typeof(setmetatable({} :: TimerUtilityData, TimerUtility))

return TimerUtility