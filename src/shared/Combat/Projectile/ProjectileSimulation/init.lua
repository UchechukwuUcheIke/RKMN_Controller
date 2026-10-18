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

local ProjectileSimulation = {}
ProjectileSimulation.__index = ProjectileSimulation

export type WallCast = Projectile.WallCast

type ProjectileSimulationData = {
	-- Fired with (projectile)
	Spawned: SignalInstance,
	-- Fired with (projectile, hurtbox, hitResult) for every hit that reaches a target
	Hit: SignalInstance,
	-- Fired with (projectile, outcome), where outcome is never InFlight
	Despawned: SignalInstance,

	_hitboxes: HitboxRegistry.HitboxRegistry,
	_wallCast: WallCast,
	_active: { Projectile },
}

type ProjectileSimulationPrototype = typeof(ProjectileSimulation)

export type ProjectileSimulation = typeof(setmetatable(
	{} :: ProjectileSimulationData,
	{} :: ProjectileSimulationPrototype
))

-- Projectiles register their hitboxes in `hitboxes`, which the frame's hit pass (a HitResolver
-- over the same registry) delivers hits for.
function ProjectileSimulation.new(hitboxes: HitboxRegistry.HitboxRegistry, wallCast: WallCast): ProjectileSimulation
	local data: ProjectileSimulationData = {
		Spawned = Signal.new(),
		Hit = Signal.new(),
		Despawned = Signal.new(),

		_hitboxes = hitboxes,
		_wallCast = wallCast,
		_active = {},
	}

	return setmetatable(data, ProjectileSimulation)
end

function ProjectileSimulation.GetActive(self: ProjectileSimulation): { Projectile }
	return self._active
end

-- Fire rate is the weapon's business; the simulation spawns whatever it is asked to.
function ProjectileSimulation.Spawn(
	self: ProjectileSimulation,
	definition: ProjectileDefinition,
	ownerId: number,
	team: Team,
	position: Vector2,
	direction: Direction
): Projectile
	local projectile = Projectile.new(definition, ownerId, team, position, direction, function(shot, hurtbox, result)
		self.Hit:Fire(shot, hurtbox, result)
	end)
	table.insert(self._active, projectile)
	self._hitboxes:Register(projectile.Hitbox)
	self.Spawned:Fire(projectile)

	return projectile
end

-- First half of a frame: moves every projectile's hitbox over its step. The hit pass runs between
-- this and Settle.
function ProjectileSimulation.Advance(self: ProjectileSimulation, dt: number): ()
	-- Snapshot, so shots spawned or removed by callbacks don't disturb this pass.
	for _, projectile in table.clone(self._active) do
		if table.find(self._active, projectile) then
			projectile:Advance(dt, self._wallCast)
		end
	end
end

-- Second half of a frame: finishes every projectile's move given where the hit pass stopped each
-- hitbox, and despawns the ones that ended.
function ProjectileSimulation.Settle(self: ProjectileSimulation, stops: HitResolver.StopFractions): ()
	for _, projectile in table.clone(self._active) do
		local index = table.find(self._active, projectile)
		if not index then
			continue
		end

		local outcome = projectile:Settle(stops[projectile.Hitbox])
		if outcome ~= ProjectileStepOutcome.InFlight then
			table.remove(self._active, index)
			self._hitboxes:Unregister(projectile.Hitbox)
			self.Despawned:Fire(projectile, outcome)
		end
	end
end

function ProjectileSimulation.Destroy(self: ProjectileSimulation): ()
	for _, projectile in self._active do
		self._hitboxes:Unregister(projectile.Hitbox)
	end

	self.Spawned:Destroy()
	self.Hit:Destroy()
	self.Despawned:Destroy()
	table.clear(self._active)
	setmetatable(self :: any, nil)
end

return ProjectileSimulation
