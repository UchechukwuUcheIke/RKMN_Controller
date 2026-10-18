--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Direction = require(ReplicatedStorage.Data.Direction)
local Bounds = require(DataFolder.Bounds)
local DamageTemplate = require(DataFolder.DamageTemplate)
local PostHitReaction = require(CombatFolder.Hitbox.PostHitReaction)
local HitResult = require(CombatFolder.Hurtbox.HitResult)
local Hurtbox = require(CombatFolder.Hurtbox.Hurtbox)
local Team = require(DataFolder.Team)

type Bounds = Bounds.Bounds
type DamageTemplate = DamageTemplate.DamageTemplate
type Direction = Direction.Direction
type PostHitReaction = PostHitReaction.PostHitReaction
type HitResult = HitResult.HitResult
type Hurtbox = Hurtbox.Hurtbox
type Team = Team.Team

local Hitbox = {}
Hitbox.__index = Hitbox

export type OnHitCallback = (hurtbox: Hurtbox, result: HitResult) -> PostHitReaction

export type HitboxConfig = {
	OwnerId: number,
	Team: Team,
	Center: Vector2,
	Size: Vector2,
	Damage: DamageTemplate,
	Direction: Direction,
	OnHit: OnHitCallback?,
	Enabled: boolean?,
}

type HitboxData = {
	OwnerId: number,
	Team: Team,
	Enabled: boolean,
	Size: Vector2,
	Damage: DamageTemplate,
	Direction: Direction,
	OnHit: OnHitCallback?,
	ReachFraction: number,

	_center: Vector2,
	_previousCenter: Vector2,
	_hitTargets: { [Hurtbox]: boolean },
}

type HitboxPrototype = typeof(Hitbox)

export type Hitbox = typeof(setmetatable(
	{} :: HitboxData,
	{} :: HitboxPrototype
))

function Hitbox.new(config: HitboxConfig): Hitbox
	assert(config.Size.X > 0 and config.Size.Y > 0, "Hitbox Size must be positive on both axes")

	local data: HitboxData = {
		OwnerId = config.OwnerId,
		Team = config.Team,
		Enabled = if config.Enabled == nil then true else config.Enabled,
		Size = config.Size,
		Damage = config.Damage,
		Direction = config.Direction,
		OnHit = config.OnHit,
		ReachFraction = 1,

		_center = config.Center,
		_previousCenter = config.Center,
		_hitTargets = {},
	}

	return setmetatable(data, Hitbox)
end

function Hitbox.GetCenter(self: Hitbox): Vector2
	return self._center
end

function Hitbox.GetPreviousCenter(self: Hitbox): Vector2
	return self._previousCenter
end

function Hitbox.MoveTo(self: Hitbox, center: Vector2): ()
	self._previousCenter = self._center
	self._center = center
end

function Hitbox.Teleport(self: Hitbox, center: Vector2): ()
	self._previousCenter = center
	self._center = center
end

function Hitbox.SetReachFraction(self: Hitbox, reachFraction: number): ()
	assert(reachFraction >= 0 and reachFraction <= 1, "Hitbox ReachFraction must be between 0 and 1")
	self.ReachFraction = reachFraction
end

function Hitbox.Resize(self: Hitbox, size: Vector2): ()
	assert(size.X > 0 and size.Y > 0, "Hitbox Size must be positive on both axes")
	self.Size = size
end

function Hitbox.GetSweptBounds(self: Hitbox): Bounds
	return Bounds.fromSweep(self._previousCenter, self._center, self.Size)
end

function Hitbox.HasHit(self: Hitbox, hurtbox: Hurtbox): boolean
	return self._hitTargets[hurtbox] == true
end

function Hitbox.RecordHit(self: Hitbox, hurtbox: Hurtbox): ()
	self._hitTargets[hurtbox] = true
end

return Hitbox
