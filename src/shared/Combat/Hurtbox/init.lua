--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local Bounds = require(CombatFolder.Bounds)
local DamagePayload = require(CombatFolder.DamagePayload)
local HitResult = require(CombatFolder.HitResult)
local Team = require(CombatFolder.Team)

local Hurtbox = {}

export type Hurtbox = {
	OwnerId: number,
	Team: Team.Team,
	Enabled: boolean,
	GetBounds: () -> Bounds.Bounds,
	Receive: (damage: DamagePayload.DamagePayload) -> HitResult.HitResult,
}

return Hurtbox
