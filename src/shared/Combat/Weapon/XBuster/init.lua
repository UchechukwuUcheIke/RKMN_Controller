--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Direction = require(ReplicatedStorage.Data.Direction)
local ProjectileFolder = CombatFolder.Projectile
local Projectile = require(ProjectileFolder.Projectile)
local ProjectileSimulation = require(ProjectileFolder.ProjectileSimulation)
local Team = require(DataFolder.Team)
local WeaponFolder = CombatFolder.Weapon
local XBusterLemon = require(WeaponFolder.XBusterLemon)
local Weapon = require(WeaponFolder.Weapon)

type Direction = Direction.Direction
type ProjectileSimulation = ProjectileSimulation.ProjectileSimulation
type Team = Team.Team
type Weapon = Weapon.Weapon

local XBuster = {}
XBuster.__index = XBuster

export type Muzzle = {
	Position: Vector2,
	Direction: Direction,
}

export type MuzzleProvider = () -> Muzzle

type XBusterData = {
	_projectiles: ProjectileSimulation,
	_ownerId: number,
	_team: Team,
	_getMuzzle: MuzzleProvider,
	_enabled: boolean,
	_cooldownLeft: number,
}

type XBusterPrototype = typeof(XBuster) & Weapon

export type XBuster = typeof(setmetatable(
	{} :: XBusterData,
	{} :: XBusterPrototype
))

XBuster.Cooldown = 0.12

function XBuster.new(
	projectiles: ProjectileSimulation,
	ownerId: number,
	team: Team.Team,
	getMuzzle: MuzzleProvider
): XBuster
	local data: XBusterData = {
		_projectiles = projectiles,
		_ownerId = ownerId,
		_team = team,
		_getMuzzle = getMuzzle,
		_enabled = true,
		_cooldownLeft = 0,
	}

	return setmetatable(data, XBuster)
end

function XBuster.Update(self: XBuster, dt: number): ()
	self._cooldownLeft = math.max(0, self._cooldownLeft - dt)
end

function XBuster.PressTrigger(self: XBuster): ()
	local cannotFire = not self._enabled or self._cooldownLeft > 0
	if cannotFire then
		return
	end

	local muzzle = self._getMuzzle()
	self._cooldownLeft = XBuster.Cooldown

	local projectile = Projectile.new(XBusterLemon, self._ownerId, self._team, muzzle.Position, muzzle.Direction)
	self._projectiles:Register(projectile)
end

function XBuster.ReleaseTrigger(self: XBuster): () 
	-- Nothing to release yet: only the uncharged shot exists.
end

function XBuster.SetEnabled(self: XBuster, enabled: boolean): ()
	self._enabled = enabled
end

return XBuster
