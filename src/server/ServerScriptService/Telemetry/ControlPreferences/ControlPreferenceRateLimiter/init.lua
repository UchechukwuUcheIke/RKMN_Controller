--!strict
local ControlPreferenceRateLimiter = {}
ControlPreferenceRateLimiter.__index = ControlPreferenceRateLimiter

export type ControlPreferenceRateLimiter = typeof(setmetatable(
    {} :: {
        _cooldownSeconds: number,
        _maxPerPlayer: number,
        _clock: () -> number,
        _lastAcceptedClockByPlayer: {[Player]: number},
        _acceptedCountByPlayer: {[Player]: number}
    },
    ControlPreferenceRateLimiter
))

function ControlPreferenceRateLimiter.new(
    cooldownSeconds: number,
    maxPerPlayer: number,
    clock: (() -> number)?
): ControlPreferenceRateLimiter
    return setmetatable({
        _cooldownSeconds = cooldownSeconds,
        _maxPerPlayer = maxPerPlayer,
        _clock = clock or os.clock,
        _lastAcceptedClockByPlayer = {},
        _acceptedCountByPlayer = {},
    }, ControlPreferenceRateLimiter)
end

function ControlPreferenceRateLimiter._isCooldownOver(self: ControlPreferenceRateLimiter, player: Player): boolean
    local lastAcceptedClock = self._lastAcceptedClockByPlayer[player]
    local hasPlayerSubmittedPreferenceBefore = lastAcceptedClock ~= nil
    if not hasPlayerSubmittedPreferenceBefore then
        return true
    end

    return self._clock() - lastAcceptedClock >= self._cooldownSeconds
end

function ControlPreferenceRateLimiter._updatePlayerRateCount(self: ControlPreferenceRateLimiter, player: Player): ()
    local acceptedCount = self._acceptedCountByPlayer[player] or 0
    local now = self._clock()
    self._lastAcceptedClockByPlayer[player] = now
    self._acceptedCountByPlayer[player] = acceptedCount + 1
end

function ControlPreferenceRateLimiter._hasReachedLimit(self: ControlPreferenceRateLimiter, player: Player): boolean
    local acceptedCount = self._acceptedCountByPlayer[player] or 0
    return acceptedCount >= self._maxPerPlayer
end

function ControlPreferenceRateLimiter.TryAccept(self: ControlPreferenceRateLimiter, player: Player): boolean
    if not self:_isCooldownOver(player) then
        return false
    end

    if self:_hasReachedLimit(player) then
        return false
    end

    self:_updatePlayerRateCount(player)
    return true
end

function ControlPreferenceRateLimiter.Forget(self: ControlPreferenceRateLimiter, player: Player)
    self._lastAcceptedClockByPlayer[player] = nil
    self._acceptedCountByPlayer[player] = nil
end

return ControlPreferenceRateLimiter
