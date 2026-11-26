--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Direction = require(ReplicatedStorage.Data.Direction)
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local HitboxRegistry = require(CombatFolder.Hitbox.HitboxRegistry)
local HitResolver = require(CombatFolder.Hitbox.HitResolver)
local Projectile = require(CombatFolder.Projectile.Projectile)
local ProjectileDefinition = require(CombatFolder.Projectile.ProjectileDefinition)
local ProjectileStepOutcome = require(CombatFolder.Projectile.ProjectileStepOutcome)
local Team = require(DataFolder.Team)

type Direction = Direction.Direction
type Projectile = Projectile.Projectile
type ProjectileDefinition = ProjectileDefinition.ProjectileDefinition
type SignalInstance = typeof(Signal.new())
type ProjectileStepOutcome = ProjectileStepOutcome.ProjectileStepOutcome
type Team = Team.Team
type HitboxRegistry = HitboxRegistry.HitboxRegistry
type StopFractions = HitResolver.StopFractions

local ProjectileSimulation = {}
ProjectileSimulation.__index = ProjectileSimulation

export type WallCaster = Projectile.WallCaster

type ProjectileSimulationData = {

	ProjectileSpawned: SignalInstance,
	ProjectileHit: SignalInstance,
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
		ProjectileSpawned = Signal.new(),
		ProjectileHit = Signal.new(),
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

function ProjectileSimulation.SpawnProjectile(
	self: ProjectileSimulation,
	definition: ProjectileDefinition,
	ownerId: number,
	team: Team,
	position: Vector2,
	direction: Direction
): Projectile

	local onHitCallback = function(shot, hurtbox, result)
		self.ProjectileHit:Fire(shot, hurtbox, result)
	end

	local projectile = Projectile.new(definition, ownerId, team, position, direction, onHitCallback)
	table.insert(self._activeProjectiles, projectile)
	self._hitboxRegistry:Register(projectile.Hitbox)
	self.ProjectileSpawned:Fire(projectile)

	return projectile
end

function ProjectileSimulation.AdvanceProjectiles(self: ProjectileSimulation, dt: number): ()
	-- Snapshot, so shots spawned or removed by callbacks don't disturb this pass.
	local activeProjectiles = table.clone(self._activeProjectiles)
	for _, projectile in activeProjectiles do
		local isProjectileActive = table.find(self._activeProjectiles, projectile) ~= nil
		if isProjectileActive then
			projectile:Advance(dt, self._walls)
		end
	end
end

function ProjectileSimulation.SettleProjectiles(self: ProjectileSimulation, stops: StopFractions): ()
	local activeProjectiles = table.clone(self._activeProjectiles)
	for _, projectile in activeProjectiles do
		local projectileIndex = table.find(self._activeProjectiles, projectile)
		local isProjectileActive = projectileIndex ~= nil
		if not isProjectileActive then
			continue
		end

		local outcome = projectile:Settle(stops[projectile.Hitbox])
		if outcome ~= ProjectileStepOutcome.InFlight then
			table.remove(self._activeProjectiles, projectileIndex)
			self._hitboxRegistry:Unregister(projectile.Hitbox)
			self.ProjectileDespawned:Fire(projectile, outcome)
		end
	end
end

function ProjectileSimulation.Destroy(self: ProjectileSimulation): ()
	for _, projectile in self._activeProjectiles do
		self._hitboxRegistry:Unregister(projectile.Hitbox)
	end

	self.ProjectileSpawned:Destroy()
	self.ProjectileHit:Destroy()
	self.ProjectileDespawned:Destroy()
	table.clear(self._activeProjectiles)
	setmetatable(self :: any, nil)
end

return ProjectileSimulation
