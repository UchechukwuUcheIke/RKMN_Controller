--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Bounds = require(DataFolder.Bounds)
local DamagePayload = require(DataFolder.DamagePayload)
local HitResult = require(CombatFolder.Hurtbox.HitResult)
local Team = require(DataFolder.Team)

local Hurtbox = {}

type Bounds = Bounds.Bounds
type Team = Team.Team
type HitResult = HitResult.HitResult
type DamagePayload = DamagePayload.DamagePayload

export type Hurtbox = {
	OwnerId: number,
	Team: Team,
	Enabled: boolean,
	GetBounds: () -> Bounds,
	Receive: (damage: DamagePayload) -> HitResult,
}

return Hurtbox
