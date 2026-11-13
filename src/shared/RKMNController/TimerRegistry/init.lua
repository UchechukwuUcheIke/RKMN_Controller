--!strict

local TimerRegistry = {}
TimerRegistry.__index = TimerRegistry

type TimerRegistryData = {
    _ActiveTimers: {[string]: number},
}

export type TimerRegistry = typeof(setmetatable({} :: TimerRegistryData, TimerRegistry))

function TimerRegistry.new(): TimerRegistry
    local self = setmetatable({}, TimerRegistry)

    self._ActiveTimers = {}
    return self
end

function TimerRegistry:Step(dt: number): ()
    for id: string, remainingTime: number in pairs(self._ActiveTimers) do
        local newTime: number = remainingTime - dt
        if newTime <= 0 then
            self._ActiveTimers[id] = nil
        else
            self._ActiveTimers[id] = newTime
        end
    end
end

function TimerRegistry:StartTimer(id: string, duration: number): boolean    
    self._ActiveTimers[id] = duration

    return true
end

function TimerRegistry:GetTimeRemaining(id: string): number
    return self._ActiveTimers[id] or 0
end

function TimerRegistry:GetActiveTimers(): {[string]: number}
    local readOnlyTable = self._ActiveTimers
    return readOnlyTable
end

function TimerRegistry:IsComplete(id: string): boolean
    return self._ActiveTimers[id] == nil
end

function TimerRegistry:Cancel(id): ()
    self._ActiveTimers[id] = nil
end

function TimerRegistry:FlushAll(): ()
    table.clear(self._ActiveTimers)
end

function TimerRegistry:Destroy(): ()
    self:FlushAll()
    setmetatable(self, nil)
end

return TimerRegistry