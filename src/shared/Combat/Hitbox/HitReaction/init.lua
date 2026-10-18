--!strict
-- What a hitbox's owner wants after one of its hits lands: keep sweeping toward later targets, or end the move there.
local HitReaction = {
	Continue = "Continue",
	Stop = "Stop",
}

export type HitReaction = "Continue" | "Stop"

table.freeze(HitReaction)

return HitReaction
