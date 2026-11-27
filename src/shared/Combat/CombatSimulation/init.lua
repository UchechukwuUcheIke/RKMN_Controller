--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local HitboxFolder = CombatFolder.Hitbox
local ProjectileFolder = CombatFolder.Projectile
local WeaponFolder = CombatFolder.Weapon
local HitboxRegistry = require(HitboxFolder.HitboxRegistry)
local HitResolver = require(HitboxFolder.HitResolver)
local HurtboxRegistry = require(CombatFolder.Hurtbox.HurtboxRegistry)
local ProjectileSimulation = require(ProjectileFolder.ProjectileSimulation)
local WallQuery = require(ProjectileFolder.WallQuery)
local WeaponFacade = require(WeaponFolder.WeaponFacade)
local WeaponRegistry = require(WeaponFolder.WeaponRegistry)

type HitboxRegistry = HitboxRegistry.HitboxRegistry
type HitResolver = HitResolver.HitResolver
type HurtboxRegistry = HurtboxRegistry.HurtboxRegistry
type ProjectileSimulation = ProjectileSimulation.ProjectileSimulation
type WallQuery = WallQuery.WallQuery
type WeaponFacade = WeaponFacade.WeaponFacade

local CombatSimulation = {}
CombatSimulation.__index = CombatSimulation

type CombatSimulationData = {
	HurtboxRegistry: HurtboxRegistry,
	HitboxRegistry: HitboxRegistry,
	Projectiles: ProjectileSimulation,
	Weapons: WeaponFacade,
	Walls: WallQuery,

	_hitResolver: HitResolver,
}

type CombatSimulationPrototype = typeof(CombatSimulation)

export type CombatSimulation = typeof(setmetatable(
	{} :: CombatSimulationData,
	{} :: CombatSimulationPrototype
))

function CombatSimulation.new(walls: WallQuery): CombatSimulation
	local hurtboxes = HurtboxRegistry.new()
	local hitboxes = HitboxRegistry.new()

	local data: CombatSimulationData = {
		HurtboxRegistry = hurtboxes,
		HitboxRegistry = hitboxes,
		Projectiles = ProjectileSimulation.new(hitboxes, walls),
		Weapons = WeaponFacade.new(WeaponRegistry.new()),
		Walls = walls,

		_hitResolver = HitResolver.new(hitboxes, hurtboxes),
	}

	return setmetatable(data, CombatSimulation)
end

function CombatSimulation.Step(self: CombatSimulation, dt: number): ()
	self.Weapons:Update(dt)
	self.Projectiles:AdvanceProjectiles(dt)
	self.Projectiles:CommitProjectileMoves(self._hitResolver:Resolve())
end

function CombatSimulation.Destroy(self: CombatSimulation): ()
	self.Projectiles:Destroy()
	self._hitResolver:Destroy()
	self.HitboxRegistry:Destroy()
	self.HurtboxRegistry:Destroy()
	setmetatable(self :: any, nil)
end

return CombatSimulation
