--!strict
-- What a hitbox's owner wants after one of its hits lands: keep sweeping toward later targets, or end the move there.
local PostHitReaction = {
	Continue = "Continue",
	Stop = "Stop",
}

export type PostHitReaction = "Continue" | "Stop"

table.freeze(PostHitReaction)

return PostHitReaction
