--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Direction = require(ReplicatedStorage.Data.Direction)
local DamageTemplate = require(DataFolder.DamageTemplate)
local Projectile = require(CombatFolder.Projectile.Projectile)
local ProjectileDefinition = require(CombatFolder.Projectile.ProjectileDefinition)
local ProjectileIDs = require(CombatFolder.Projectile.ProjectileIDRegistry)
local ProjectileSimulation = require(CombatFolder.Projectile.ProjectileSimulation)
local Team = require(DataFolder.Team)

type Direction = Direction.Direction
type Projectile = Projectile.Projectile
type ProjectileDefinition = ProjectileDefinition.ProjectileDefinition
type ProjectileSimulation = ProjectileSimulation.ProjectileSimulation

local MegaBuster = {}
MegaBuster.__index = MegaBuster

-- Where a shot leaves the wielder and which way it flies (Direction.Left or Direction.Right).
export type Muzzle = {
	Position: Vector2,
	Direction: Direction,
}

-- Asked at the moment of firing, so the shot follows the wielder's current position and facing.
export type MuzzleProvider = () -> Muzzle

type MegaBusterData = {
	_projectiles: ProjectileSimulation,
	_ownerId: number,
	_team: Team.Team,
	_getMuzzle: MuzzleProvider,
	-- Seconds until the next shot is allowed
	_cooldownLeft: number,
}

type MegaBusterPrototype = typeof(MegaBuster)

export type MegaBuster = typeof(setmetatable(
	{} :: MegaBusterData,
	{} :: MegaBusterPrototype
))

-- Minimum seconds between shots.
MegaBuster.Cooldown = 0.12

-- The uncharged shot.
MegaBuster.Lemon = ProjectileDefinition.new({
	Id = ProjectileIDs.MegaBusterLemon,
	Speed = 60,
	Lifetime = 1.2,
	Size = Vector2.new(1, 1),
	Damage = DamageTemplate.new({
		Amount = 1,
		Tags = { "Buster" },
	}),
})

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
		_cooldownLeft = 0,
	}

	return setmetatable(data, MegaBuster)
end

-- Counts the cooldown down; call it every frame with the same dt the simulation steps with.
function MegaBuster.Update(self: MegaBuster, dt: number): ()
	self._cooldownLeft = math.max(0, self._cooldownLeft - dt)
end

-- Fires one lemon. Returns nil while the buster is on cooldown.
function MegaBuster.Fire(self: MegaBuster): Projectile?
	if self._cooldownLeft > 0 then
		return nil
	end

	local muzzle = self._getMuzzle()
	self._cooldownLeft = MegaBuster.Cooldown

	return self._projectiles:Spawn(MegaBuster.Lemon, self._ownerId, self._team, muzzle.Position, muzzle.Direction)
end

return MegaBuster
