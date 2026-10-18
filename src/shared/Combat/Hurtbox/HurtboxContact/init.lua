--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local Hurtbox = require(CombatFolder.Hurtbox.Hurtbox)

type Hurtbox = Hurtbox.Hurtbox

local HurtboxContact = {}

-- A hurtbox that a moving box touches during one move. No damage has been dealt yet.
export type HurtboxContact = {
	Hurtbox: Hurtbox,
	-- How far along the move the touch happens, as a fraction from 0 (start) to 1 (end)
	ContactMoveFraction: number,
}

-- contactMoveFraction must be between 0 and 1. The result is frozen.
function HurtboxContact.new(hurtbox: Hurtbox, contactMoveFraction: number): HurtboxContact
	assert(
		contactMoveFraction >= 0 and contactMoveFraction <= 1,
		"HurtboxContact ContactMoveFraction must be between 0 and 1"
	)

	local contact: HurtboxContact = {
		Hurtbox = hurtbox,
		ContactMoveFraction = contactMoveFraction,
	}

	return table.freeze(contact)
end

return HurtboxContact
