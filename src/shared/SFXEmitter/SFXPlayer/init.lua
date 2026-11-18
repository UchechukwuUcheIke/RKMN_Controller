--!strict
local SFXPlayer = {}
SFXPlayer.__index = SFXPlayer
SFXPlayer.ClassName = "SFXPlayer"

local SFXEmitterFolder = script.Parent
local SFXRegistry = require(SFXEmitterFolder.SFXRegistry)
local SoundObjectPool = require(SFXEmitterFolder.SoundObjectPool)

type SFXRegistry = SFXRegistry.SFXRegistry
type SoundObjectPool = SoundObjectPool.SoundObjectPool

type SFXPlayerData = {
	_registry: SFXRegistry,
	_pool: SoundObjectPool,
}

type SFXPlayerPrototype = typeof({__index = SFXPlayer})

export type SFXPlayer = typeof(setmetatable(
	{} :: SFXPlayerData,
	{} :: SFXPlayerPrototype))

function SFXPlayer.new(registry: SFXRegistry, pool: SoundObjectPool): SFXPlayer
	local data: SFXPlayerData = {
		_registry = registry,
		_pool = pool,
	}

	return setmetatable(data, SFXPlayer)
end

function SFXPlayer.Play(self: SFXPlayer, sfxId: string): ()
	local entry = self._registry[sfxId]
	if entry == nil or entry.SoundId == "" then
		return
	end

	local sound = self._pool:Acquire()
	sound.SoundId = entry.SoundId
	sound.Volume = entry.Volume
	sound.PlaybackSpeed = entry.PlaybackSpeed

	sound.Ended:Once(function()
		self._pool:Release(sound)
	end)
	
	sound:Play()
end

table.freeze(SFXPlayer)

return SFXPlayer
