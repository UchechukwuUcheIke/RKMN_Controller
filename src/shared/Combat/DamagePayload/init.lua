--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Team = require(ReplicatedStorage.Combat.Team)

export type DamagePayload = {
	Amount: number,
	SourceOwnerId: number,
	Team: Team.Team,
	Knockback: Vector2,
	HitstopDuration: number,
	Tags: { string },
}

return {}
