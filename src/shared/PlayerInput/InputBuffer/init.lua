--!strict
local InputBuffer = {}
InputBuffer.__index = InputBuffer

local TimerRegistryModule = require(game:GetService("ReplicatedStorage").RKMNController.TimerRegistry)
type TimerRegistry = TimerRegistryModule.TimerRegistry

type InputBufferData = {
    _timerRegistry: TimerRegistry,
    _timerId: string,
    _duration: number
}

export type InputBuffer = typeof(setmetatable({} :: InputBufferData, InputBuffer))

function InputBuffer.new(timerRegistry: TimerRegistry, timerId: string, duration: number): InputBuffer
    local self = setmetatable({}, InputBuffer)

    self._timerRegistry = timerRegistry
    self._timerId = timerId
    self._duration = duration

    return self :: InputBuffer
end

function InputBuffer.Fill(self: InputBuffer): ()
    self._timerRegistry:StartTimer(self._timerId, self._duration)
end

function InputBuffer.Consume(self: InputBuffer): boolean
    local wasFilled = self:IsFilled()
    self._timerRegistry:Cancel(self._timerId)
    return wasFilled
end

function InputBuffer.IsFilled(self: InputBuffer): boolean
    return not self._timerRegistry:IsComplete(self._timerId)
end

function InputBuffer.Destroy(self: InputBuffer): ()
    self._timerRegistry:Cancel(self._timerId)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(InputBuffer)
return InputBuffer
