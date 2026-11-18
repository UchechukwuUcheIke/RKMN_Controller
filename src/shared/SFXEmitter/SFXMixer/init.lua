--!strict
local SFXMixer = {}
SFXMixer.__index = SFXMixer
SFXMixer.ClassName = "SFXMixer"

type SFXMixerData = {
	_soundGroup: SoundGroup,
	_volume: number,
	_isMuted: boolean,
}

type SFXMixerPrototype = typeof({__index = SFXMixer})

export type SFXMixer = typeof(setmetatable(
	{} :: SFXMixerData,
	{} :: SFXMixerPrototype))

function SFXMixer.new(parent: Instance): SFXMixer
	local soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = "SFXGroup"
	soundGroup.Parent = parent

	local data: SFXMixerData = {
		_soundGroup = soundGroup,
		_volume = soundGroup.Volume,
		_isMuted = false,
	}

	return setmetatable(data, SFXMixer)
end

function SFXMixer._applyVolumeChange(self: SFXMixer): ()
	self._soundGroup.Volume = if self._isMuted then 0 else self._volume
end

function SFXMixer.GetSoundGroup(self: SFXMixer): SoundGroup
	return self._soundGroup
end

function SFXMixer.SetVolume(self: SFXMixer, volume: number): ()
	self._volume = math.max(volume, 0)
	self:_applyVolumeChange()
end

function SFXMixer.SetMuted(self: SFXMixer, isMuted: boolean): ()
	self._isMuted = isMuted
	self:_applyVolumeChange()
end

function SFXMixer.Destroy(self: SFXMixer): ()
	self._soundGroup:Destroy()
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(SFXMixer)

return SFXMixer
