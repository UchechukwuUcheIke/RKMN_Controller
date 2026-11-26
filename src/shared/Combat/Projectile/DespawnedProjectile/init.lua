--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local ProjectileFolder = CombatFolder.Projectile
local Projectile = require(ProjectileFolder.Projectile)
local ProjectileStepOutcome = require(ProjectileFolder.ProjectileStepOutcome)

type Projectile = Projectile.Projectile
type ProjectileStepOutcome = ProjectileStepOutcome.ProjectileStepOutcome

local DespawnedProjectile = {}

export type DespawnedProjectile = {
	Projectile: Projectile,
	Outcome: ProjectileStepOutcome,
}

function DespawnedProjectile.new(projectile: Projectile, outcome: ProjectileStepOutcome): DespawnedProjectile
	assert(outcome ~= ProjectileStepOutcome.InFlight, "DespawnedProjectile Outcome must not be InFlight")

	local despawnedProjectile: DespawnedProjectile = {
		Projectile = projectile,
		Outcome = outcome,
	}

	return table.freeze(despawnedProjectile)
end

return DespawnedProjectile
