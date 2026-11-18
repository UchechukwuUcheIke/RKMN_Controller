--!strict
local AnimationTrackPlayer = {}
AnimationTrackPlayer.__index = AnimationTrackPlayer
AnimationTrackPlayer.ClassName = "AnimationTrackPlayer"

local MovementAnimationSet = require(script.Parent.MovementAnimationSet)

type AnimationEntry = MovementAnimationSet.AnimationEntry

const NO_FADE = 0

type AnimationTrackPlayerData = {
	_animator: Animator,
	_tracksById: { [string]: AnimationTrack },
	_currentAnimationId: string?,
	_currentTrack: AnimationTrack?,
}

type AnimationTrackPlayerPrototype = typeof({__index = AnimationTrackPlayer})

export type AnimationTrackPlayer = typeof(setmetatable(
	{} :: AnimationTrackPlayerData,
	{} :: AnimationTrackPlayerPrototype))

function AnimationTrackPlayer.new(animator: Animator): AnimationTrackPlayer
	local data: AnimationTrackPlayerData = {
		_animator = animator,
		_tracksById = {},
		_currentAnimationId = nil,
		_currentTrack = nil,
	}

	return setmetatable(data, AnimationTrackPlayer)
end

function AnimationTrackPlayer._getTrack(self: AnimationTrackPlayer, entry: AnimationEntry): AnimationTrack
	-- NOTE: May be worth it to populate cache on init.
	local cachedTrack = self._tracksById[entry.AnimationId]
	if cachedTrack then
		return cachedTrack
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = entry.AnimationId
	local track = self._animator:LoadAnimation(animation)
	animation:Destroy()

	track.Looped = entry.IsLooped
	track.Priority = entry.Priority
	self._tracksById[entry.AnimationId] = track

	return track
end

function AnimationTrackPlayer.Play(self: AnimationTrackPlayer, entry: AnimationEntry): ()
	if self._currentAnimationId == entry.AnimationId then
		return
	end

	self:Stop()

	local track = self:_getTrack(entry)
	track:Play(NO_FADE)
	self._currentAnimationId = entry.AnimationId
	self._currentTrack = track
end

function AnimationTrackPlayer.Stop(self: AnimationTrackPlayer): ()
	local currentTrack = self._currentTrack
	if currentTrack then
		currentTrack:Stop(NO_FADE)
	end

	self._currentAnimationId = nil
	self._currentTrack = nil
end

function AnimationTrackPlayer._clearTrackTable(self: AnimationTrackPlayer): ()
	for _, track in self._tracksById do
		track:Destroy()
	end
	table.clear(self._tracksById)
end

function AnimationTrackPlayer.Destroy(self: AnimationTrackPlayer): ()
	self:Stop()
	self:_clearTrackTable()
	setmetatable(self :: any, nil)
	table.freeze(self)	
end

table.freeze(AnimationTrackPlayer)

return AnimationTrackPlayer
