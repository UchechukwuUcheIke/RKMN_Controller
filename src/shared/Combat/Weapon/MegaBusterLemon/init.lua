--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DamageTemplate = require(CombatFolder.Data.DamageTemplate)
local ProjectileDefinition = require(CombatFolder.Projectile.ProjectileDefinition)
local ProjectileIDs = require(CombatFolder.Projectile.ProjectileIDRegistry)

return ProjectileDefinition.new({
	Id = ProjectileIDs.MegaBusterLemon,
	Speed = 60,
	Lifetime = 1.2,
	Size = Vector2.new(1, 1),
	Damage = DamageTemplate.new({
		Amount = 1,
		Tags = { "Buster" },
	}),
})
