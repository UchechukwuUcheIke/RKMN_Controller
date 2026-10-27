--!strict
local InputBuffer = {}
InputBuffer.__index = InputBuffer

local TimerUtilityModule = require(game:GetService("ReplicatedStorage").RKMNController.TimerUtility)
type TimerUtility = TimerUtilityModule.TimerUtility

type InputBufferData = {
    _timerUtility: TimerUtility,
    _timerId: string,
    _duration: number
}

export type InputBuffer = typeof(setmetatable({} :: InputBufferData, InputBuffer))

function InputBuffer.new(timerUtility: TimerUtility, timerId: string, duration: number): InputBuffer
    local self = setmetatable({}, InputBuffer)

    self._timerUtility = timerUtility
    self._timerId = timerId
    self._duration = duration

    return self :: InputBuffer
end

function InputBuffer.Fill(self: InputBuffer): ()
    self._timerUtility:StartTimer(self._timerId, self._duration)
end

function InputBuffer.Consume(self: InputBuffer): boolean
    local wasFilled = self:IsFilled()
    self._timerUtility:Cancel(self._timerId)
    return wasFilled
end

function InputBuffer.IsFilled(self: InputBuffer): boolean
    return not self._timerUtility:IsComplete(self._timerId)
end

function InputBuffer.Destroy(self: InputBuffer): ()
    self._timerUtility:Cancel(self._timerId)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(InputBuffer)
return InputBuffer
