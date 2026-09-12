--!strict

local TimerUtility = {}
TimerUtility.__index = TimerUtility

local Types = require(script.Parent.Types)

type TimerUtilityData = {
    _ActiveTimers: {[string]: number},
}

export type TimerUtility = typeof(setmetatable({} :: Types.TimerUtilityData, TimerUtility))

function TimerUtility.new(): TimerUtility
    local self = setmetatable({}, TimerUtility)

    self._ActiveTimers = {}
    return self
end

function TimerUtility:Step(dt: number): ()
    for id: number, remainingTime: number in pairs(self._ActiveTimers) do
        local newTime: number = remainingTime - dt
        if newTime <= 0 then
            self._ActiveTimers[id] = nil
        else
            self._ActiveTimers[id] = newTime
        end
    end
end

function TimerUtility:StartTimer(id: string, duration: number): boolean    
    self._ActiveTimers[id] = duration

    return true
end

function TimerUtility:GetTimeRemaining(id: string): number
    return self._ActiveTimers[id] or 0
end

function TimerUtility:GetActiveTimers(): {[string]: number}
    local readOnlyTable = self._ActiveTimers
    return readOnlyTable
end

function TimerUtility:IsComplete(id: string): boolean
    return self._ActiveTimers[id] == nil
end

function TimerUtility:Cancel(id): ()
    self._ActiveTimers[id] = nil
end

function TimerUtility:FlushAll(): ()
    table.clear(self._ActiveTimers)
end

function TimerUtility:Destroy(): ()
    self:FlushAll()
    setmetatable(self, nil)
end

return TimerUtility