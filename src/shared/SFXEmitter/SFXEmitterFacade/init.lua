--!strict
local SFXEmitterFacade = {}
SFXEmitterFacade.__index = SFXEmitterFacade
SFXEmitterFacade.ClassName = "SFXEmitterFacade"

local SoundService = game:GetService("SoundService")

local SFXEmitterFolder = script.Parent
local SFXRegistry = require(SFXEmitterFolder.SFXRegistry)
local SoundObjectPool = require(SFXEmitterFolder.SoundObjectPool)
local SFXMixer = require(SFXEmitterFolder.SFXMixer)
local SFXPlayer = require(SFXEmitterFolder.SFXPlayer)
local SFXBinder = require(SFXEmitterFolder.SFXBinder)

type SFXRegistry = SFXRegistry.SFXRegistry
type SoundObjectPool = SoundObjectPool.SoundObjectPool
type SFXMixer = SFXMixer.SFXMixer
type SFXPlayer = SFXPlayer.SFXPlayer
type SFXBinder = SFXBinder.SFXBinder
type BindableSignal = SFXBinder.BindableSignal

export type SFXEmitterConfig = {
	Registry: SFXRegistry?,
	Parent: Instance?,
}

type SFXEmitterFacadeData = {
	_folder: Folder,
	_pool: SoundObjectPool,
	_mixer: SFXMixer,
	_player: SFXPlayer,
	_binder: SFXBinder,
}

type SFXEmitterFacadePrototype = typeof({__index = SFXEmitterFacade})

export type SFXEmitterFacade = typeof(setmetatable(
	{} :: SFXEmitterFacadeData,
	{} :: SFXEmitterFacadePrototype))

function SFXEmitterFacade.new(config: SFXEmitterConfig?): SFXEmitterFacade
	local registry = if config and config.Registry then config.Registry else SFXRegistry
	local parent = if config and config.Parent then config.Parent else SoundService

	local folder = Instance.new("Folder")
	folder.Name = "SFX"
	folder.Parent = parent

	local mixer = SFXMixer.new(folder)
	local pool = SoundObjectPool.new(function(): Sound
		local sound = Instance.new("Sound")
		sound.SoundGroup = mixer:GetSoundGroup()
		sound.Parent = folder
		return sound
	end)
	local player = SFXPlayer.new(registry, pool)

	local data: SFXEmitterFacadeData = {
		_folder = folder,
		_pool = pool,
		_mixer = mixer,
		_player = player,
		_binder = SFXBinder.new(player),
	}

	return setmetatable(data, SFXEmitterFacade)
end

function SFXEmitterFacade.Play(self: SFXEmitterFacade, sfxId: string): ()
	self._player:Play(sfxId)
end

function SFXEmitterFacade.Bind(
	self: SFXEmitterFacade,
	signal: BindableSignal,
	sfxId: string,
	shouldPlay: ((...any) -> boolean)?)

	return self._binder:Bind(signal, sfxId, shouldPlay)
end

function SFXEmitterFacade.SetVolume(self: SFXEmitterFacade, volume: number): ()
	self._mixer:SetVolume(volume)
end

function SFXEmitterFacade.SetMuted(self: SFXEmitterFacade, isMuted: boolean): ()
	self._mixer:SetMuted(isMuted)
end

function SFXEmitterFacade.Destroy(self: SFXEmitterFacade): ()
	self._binder:Destroy()
	self._pool:Destroy()
	self._mixer:Destroy()
	self._folder:Destroy()
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(SFXEmitterFacade)

return SFXEmitterFacade
