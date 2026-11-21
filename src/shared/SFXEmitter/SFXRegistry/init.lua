--!strict
local SFXIDs = require(script.Parent.SFXIDs)

export type SFXEntry = {
	SoundId: string,
	Volume: number,
	PlaybackSpeed: number,
}

export type SFXRegistry = { [string]: SFXEntry }

local function SFXEntry(newSoundId: string, newVolume: number?, newSpeed: number?): SFXEntry
	local soundId = newSoundId or ""
	local volume = newVolume or 1
	local speed = newSpeed or 1
	return table.freeze({
		SoundId = soundId,
		Volume = volume,
		PlaybackSpeed = speed,
	})
end

local SFXRegistry: SFXRegistry = {
	[SFXIDs.Jump] = SFXEntry("79506152808870"),
	[SFXIDs.WallJump] = SFXEntry("79506152808870"),
	[SFXIDs.Dash] = SFXEntry("78825264077928"),
	[SFXIDs.Land] = SFXEntry("120170393329204"),
}

return table.freeze(SFXRegistry)
