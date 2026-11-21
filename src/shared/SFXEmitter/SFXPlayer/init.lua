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
	_pools: { [string]: SoundObjectPool },
}

type SFXPlayerPrototype = typeof({__index = SFXPlayer})

export type SFXPlayer = typeof(setmetatable(
	{} :: SFXPlayerData,
	{} :: SFXPlayerPrototype))

-- pools holds one SoundObjectPool per SFX id, whose sounds are already configured for that id.
function SFXPlayer.new(registry: SFXRegistry, pools: { [string]: SoundObjectPool }): SFXPlayer
	local data: SFXPlayerData = {
		_registry = registry,
		_pools = pools,
	}

	return setmetatable(data, SFXPlayer)
end

function SFXPlayer.Play(self: SFXPlayer, sfxId: string): ()
	local entry = self._registry[sfxId]
	local pool = self._pools[sfxId]
	if entry == nil or pool == nil or entry.SoundId == "" then
		return
	end

	-- The pool's sounds already carry this entry's SoundId, Volume and PlaybackSpeed, so nothing reloads here.
	local sound = pool:Acquire()

	sound.Ended:Once(function()
		pool:Release(sound)
	end)
	
	sound:Play()
end

table.freeze(SFXPlayer)

return SFXPlayer
