--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local HurtboxFolder = CombatFolder.Hurtbox
local Hurtbox = require(HurtboxFolder.Hurtbox)

type Hurtbox = Hurtbox.Hurtbox

local HurtboxContact = {}

export type HurtboxContact = {
	Hurtbox: Hurtbox,
	ContactMoveFraction: number,
}

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
