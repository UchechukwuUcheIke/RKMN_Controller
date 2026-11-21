--!strict
local SFXIDs = require(script.Parent.SFXIDs)

export type SFXEntry = {
	SoundId: string,
	Volume: number,
	PlaybackSpeed: number,
}

export type SFXRegistry = { [string]: SFXEntry }

local function SFXEntry(newSoundId: string, newVolume: number?, newSpeed: number?): SFXEntry
	local soundId = if newSoundId == "" then "" else "rbxassetid://" .. newSoundId
	local volume = newVolume or 1
	local speed = newSpeed or 1
	return table.freeze({
		SoundId = soundId,
		Volume = volume,
		PlaybackSpeed = speed,
	})
end

local SFXRegistry: SFXRegistry = {
	[SFXIDs.Jump] = SFXEntry("122285439744207"),
	[SFXIDs.WallJump] = SFXEntry("122285439744207"),
	[SFXIDs.Dash] = SFXEntry("125799063437606"),
	[SFXIDs.Land] = SFXEntry("123918344791559"),
}

return table.freeze(SFXRegistry)
