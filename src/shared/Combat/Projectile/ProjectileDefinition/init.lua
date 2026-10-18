--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local DamageTemplate = require(DataFolder.DamageTemplate)
local ProjectileIDRegistry = require(CombatFolder.Projectile.ProjectileIDRegistry)

type DamageTemplate = DamageTemplate.DamageTemplate
type ProjectileID = ProjectileIDRegistry.ProjectileID

local ProjectileDefinition = {}

export type ProjectileDefinition = {
	Id: ProjectileID,
	Speed: number,
	Lifetime: number,
	Size: Vector2,
	Damage: DamageTemplate,
	TargetPenetrationLimit: number,
}

export type ProjectileDefinitionConfig = {
	Id: ProjectileID,
	Speed: number,
	Lifetime: number,
	Size: Vector2,
	Damage: DamageTemplate,
	TargetPenetrationLimit: number?,
}

local function validateConfig(config: ProjectileDefinitionConfig)
	assert(config.Speed > 0, "ProjectileDefinition Speed must be positive")
	assert(config.Lifetime > 0, "ProjectileDefinition Lifetime must be positive")
	assert(config.Size.X > 0 and config.Size.Y > 0, "ProjectileDefinition Size must be positive on both axes")

end

function ProjectileDefinition.new(config: ProjectileDefinitionConfig): ProjectileDefinition
	validateConfig(config)
	
	local targetPenetrationLimit = config.TargetPenetrationLimit or 0
	assert(targetPenetrationLimit >= 0, "ProjectileDefinition TargetPenetrationLimit must not be negative")

	local definition: ProjectileDefinition = {
		Id = config.Id,
		Speed = config.Speed,
		Lifetime = config.Lifetime,
		Size = config.Size,
		Damage = config.Damage,
		TargetPenetrationLimit = targetPenetrationLimit,
	}

	return table.freeze(definition)
end

return ProjectileDefinition
