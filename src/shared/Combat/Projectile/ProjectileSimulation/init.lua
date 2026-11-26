--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DespawnedProjectile = require(CombatFolder.Projectile.DespawnedProjectile)
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local HitboxRegistry = require(CombatFolder.Hitbox.HitboxRegistry)
local HitResolver = require(CombatFolder.Hitbox.HitResolver)
local Projectile = require(CombatFolder.Projectile.Projectile)
local ProjectileStepOutcome = require(CombatFolder.Projectile.ProjectileStepOutcome)

type DespawnedProjectile = DespawnedProjectile.DespawnedProjectile
type Projectile = Projectile.Projectile
type SignalInstance = typeof(Signal.new())
type ProjectileStepOutcome = ProjectileStepOutcome.ProjectileStepOutcome
type HitboxRegistry = HitboxRegistry.HitboxRegistry
type StopFractions = HitResolver.StopFractions

local ProjectileSimulation = {}
ProjectileSimulation.__index = ProjectileSimulation

export type WallCaster = Projectile.WallCaster

type ProjectileSimulationData = {

	ProjectileRegistered: SignalInstance,
	ProjectileDespawned: SignalInstance,

	_hitboxRegistry: HitboxRegistry,
	_walls: WallCaster,
	_activeProjectiles: { Projectile },
}

type ProjectileSimulationPrototype = typeof(ProjectileSimulation)

export type ProjectileSimulation = typeof(setmetatable(
	{} :: ProjectileSimulationData,
	{} :: ProjectileSimulationPrototype
))

function ProjectileSimulation.new(hitboxRegistry: HitboxRegistry, walls: WallCaster): ProjectileSimulation
	local data: ProjectileSimulationData = {
		ProjectileRegistered = Signal.new(),
		ProjectileDespawned = Signal.new(),

		_hitboxRegistry = hitboxRegistry,
		_walls = walls,
		_activeProjectiles = {},
	}

	return setmetatable(data, ProjectileSimulation)
end

function ProjectileSimulation.GetActiveProjectiles(self: ProjectileSimulation): { Projectile }
	return self._activeProjectiles
end

function ProjectileSimulation.Register(self: ProjectileSimulation, projectile: Projectile): ()
	assert(not table.find(self._activeProjectiles, projectile), "Projectile is already registered")

	table.insert(self._activeProjectiles, projectile)
	self._hitboxRegistry:Register(projectile.Hitbox)
	self.ProjectileRegistered:Fire(projectile)
end

function ProjectileSimulation.AdvanceProjectiles(self: ProjectileSimulation, dt: number): ()
	for _, projectile in self._activeProjectiles do
		projectile:Advance(dt, self._walls)
	end
end

function ProjectileSimulation.CommitProjectileMoves(self: ProjectileSimulation, stops: StopFractions): ()
	local despawnedProjectiles: { DespawnedProjectile } = {}

	for index = #self._activeProjectiles, 1, -1 do
		local projectile = self._activeProjectiles[index]
		local outcome = projectile:CommitMove(stops[projectile.Hitbox])
		if outcome ~= ProjectileStepOutcome.InFlight then
			table.remove(self._activeProjectiles, index)
			self._hitboxRegistry:Unregister(projectile.Hitbox)
			local despawnedProjectile = DespawnedProjectile.new(projectile, outcome :: ProjectileStepOutcome)
			table.insert(despawnedProjectiles, despawnedProjectile)
		end
	end

	self:_fireDespawnedEventForProjectiles(despawnedProjectiles)	
end

function ProjectileSimulation._fireDespawnedEventForProjectiles(self: ProjectileSimulation, despawnedProjectiles: { DespawnedProjectile })
	for _, entry in despawnedProjectiles do
		self.ProjectileDespawned:Fire(entry.Projectile, entry.Outcome)
	end
end

function ProjectileSimulation.Destroy(self: ProjectileSimulation): ()
	for _, projectile in self._activeProjectiles do
		self._hitboxRegistry:Unregister(projectile.Hitbox)
	end

	self.ProjectileRegistered:Destroy()
	self.ProjectileDespawned:Destroy()
	table.clear(self._activeProjectiles)
	setmetatable(self :: any, nil)
end

return ProjectileSimulation
