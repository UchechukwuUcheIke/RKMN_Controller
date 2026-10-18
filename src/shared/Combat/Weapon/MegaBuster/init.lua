--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Direction = require(ReplicatedStorage.Data.Direction)
local ProjectileFolder = CombatFolder.Projectile
local ProjectileSimulation = require(ProjectileFolder.ProjectileSimulation)
local Team = require(DataFolder.Team)
local WeaponFolder = CombatFolder.Weapon
local MegaBusterLemon = require(WeaponFolder.MegaBusterLemon)
local Weapon = require(WeaponFolder.Weapon)

type Direction = Direction.Direction
type ProjectileSimulation = ProjectileSimulation.ProjectileSimulation
type Team = Team.Team
type Weapon = Weapon.Weapon

local MegaBuster = {}
MegaBuster.__index = MegaBuster

export type Muzzle = {
	Position: Vector2,
	Direction: Direction,
}

export type MuzzleProvider = () -> Muzzle

type MegaBusterData = {
	_projectiles: ProjectileSimulation,
	_ownerId: number,
	_team: Team,
	_getMuzzle: MuzzleProvider,
	_enabled: boolean,
	_cooldownLeft: number,
}

type MegaBusterPrototype = typeof(MegaBuster) & Weapon

export type MegaBuster = typeof(setmetatable(
	{} :: MegaBusterData,
	{} :: MegaBusterPrototype
))

MegaBuster.Cooldown = 0.12

function MegaBuster.new(
	projectiles: ProjectileSimulation,
	ownerId: number,
	team: Team.Team,
	getMuzzle: MuzzleProvider
): MegaBuster
	local data: MegaBusterData = {
		_projectiles = projectiles,
		_ownerId = ownerId,
		_team = team,
		_getMuzzle = getMuzzle,
		_enabled = true,
		_cooldownLeft = 0,
	}

	return setmetatable(data, MegaBuster)
end

function MegaBuster.Update(self: MegaBuster, dt: number): ()
	self._cooldownLeft = math.max(0, self._cooldownLeft - dt)
end

function MegaBuster.PressTrigger(self: MegaBuster): ()
	local cannotFire = not self._enabled or self._cooldownLeft > 0
	if cannotFire then
		return
	end

	local muzzle = self._getMuzzle()
	self._cooldownLeft = MegaBuster.Cooldown

	self._projectiles:Spawn(MegaBusterLemon, self._ownerId, self._team, muzzle.Position, muzzle.Direction)
end

function MegaBuster.ReleaseTrigger(self: MegaBuster): () 
	-- Nothing to release yet: only the uncharged shot exists.
end

function MegaBuster.SetEnabled(self: MegaBuster, enabled: boolean): ()
	self._enabled = enabled
end

return MegaBuster
