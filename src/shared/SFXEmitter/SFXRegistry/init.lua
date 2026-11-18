--!strict
local SFXIDs = require(script.Parent.SFXIDs)

export type SFXEntry = {
	SoundId: string,
	Volume: number,
	PlaybackSpeed: number,
}

export type SFXRegistry = { [string]: SFXEntry }

-- An empty SoundId is a placeholder: the player skips it silently until the asset is filled in.
-- TODO: Replace this w/ a dedicated class? Loose table? etc
local function entry(): SFXEntry
	return table.freeze({
		SoundId = "",
		Volume = 1,
		PlaybackSpeed = 1,
	})
end

local SFXRegistry: SFXRegistry = {
	[SFXIDs.Jump] = entry(),
	[SFXIDs.WallJump] = entry(),
	[SFXIDs.Dash] = entry(),
}

return table.freeze(SFXRegistry)
