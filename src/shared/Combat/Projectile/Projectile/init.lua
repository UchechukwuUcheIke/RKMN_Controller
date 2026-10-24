--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Direction = require(ReplicatedStorage.Data.Direction)
local PostHitReaction = require(CombatFolder.Hitbox.PostHitReaction)
local HitResult = require(CombatFolder.Hurtbox.HitResult)
local Hitbox = require(CombatFolder.Hitbox.Hitbox)
local Hurtbox = require(CombatFolder.Hurtbox.Hurtbox)
local ProjectileDefinition = require(CombatFolder.Projectile.ProjectileDefinition)
local ProjectileStepOutcome = require(CombatFolder.Projectile.ProjectileStepOutcome)
local Team = require(DataFolder.Team)

type Direction = Direction.Direction
type PostHitReaction = PostHitReaction.PostHitReaction
type HitResult = HitResult.HitResult
type Hitbox = Hitbox.Hitbox
type Hurtbox = Hurtbox.Hurtbox
type ProjectileDefinition = ProjectileDefinition.ProjectileDefinition
type ProjectileStepOutcome = ProjectileStepOutcome.ProjectileStepOutcome

local Projectile = {}
Projectile.__index = Projectile

-- What a projectile needs to know about level geometry. Injected so projectiles never touch Workspace.
export type WallCaster = {
	-- Looks along a segment for walls. Returns how far along it (0 to 1) the first
	-- obstruction is, or nil when the way is clear.
	FindFractionToWall: (self: any, from: Vector2, to: Vector2) -> number?,
}

-- Told about every hit the projectile's hitbox delivers, including ones the target ignored.
export type HitObserver = (projectile: Projectile, hurtbox: Hurtbox, result: HitResult) -> ()

type ProjectileData = {
	Definition: ProjectileDefinition,
	OwnerId: number,
	Team: Team.Team,
	Direction: Direction,
	Position: Vector2,
	Velocity: Vector2,
	TimeLeft: number,
	HitCount: number,
	Hitbox: Hitbox,

	_onHit: HitObserver?,
	-- Why the hitbox was stopped, if it was.
	_stopOutcome: ProjectileStepOutcome,
	-- The move being resolved: set by Advance, consumed by Settle.
	_isAdvanced: boolean,
	_stepDt: number,
	_stepFrom: Vector2,
	_stepTo: Vector2,
	_wallFraction: number?,
}

type ProjectilePrototype = typeof(Projectile)

export type Projectile = typeof(setmetatable(
	{} :: ProjectileData,
	{} :: ProjectilePrototype
))

-- direction must be Direction.Left or Direction.Right.
function Projectile.new(
	definition: ProjectileDefinition,
	ownerId: number,
	team: Team.Team,
	position: Vector2,
	direction: Direction,
	onHit: HitObserver?
): Projectile
	assert(direction == Direction.Left or direction == Direction.Right, "Projectile direction must be Left or Right")

	local projectile: Projectile

	local hitbox = Hitbox.new({
		OwnerId = ownerId,
		Team = team,
		Center = position,
		Size = definition.Size,
		Damage = definition.Damage,
		Direction = direction,
		OnHit = function(hurtbox: Hurtbox, result: HitResult): PostHitReaction
			return projectile:_reactToHit(hurtbox, result)
		end,
	})

	local data: ProjectileData = {
		Definition = definition,
		OwnerId = ownerId,
		Team = team,
		Direction = direction,
		Position = position,
		Velocity = Vector2.new(definition.Speed * direction.X, 0),
		TimeLeft = definition.Lifetime,
		HitCount = 0,
		Hitbox = hitbox,

		_onHit = onHit,
		_stopOutcome = ProjectileStepOutcome.InFlight,
		_isAdvanced = false,
		_stepDt = 0,
		_stepFrom = position,
		_stepTo = position,
		_wallFraction = nil,
	}

	projectile = setmetatable(data, Projectile)
	return projectile
end

-- Where the projectile would be after dt seconds, without moving it.
-- Kept as its own step so other trajectories only need to change this.
function Projectile.Project(self: Projectile, dt: number): Vector2
	return self.Position + self.Velocity * dt
end

-- Whether a hit ends the projectile. A target that ignored the hit wasn't really struck, so the
-- shot flies on and may try it again. Blocking ends it even with penetration left.
function Projectile._reactToHit(self: Projectile, hurtbox: Hurtbox, result: HitResult): PostHitReaction
	if self._onHit then
		self._onHit(self, hurtbox, result)
	end

	if result == HitResult.Ignored then
		return PostHitReaction.Continue
	end

	self.HitCount += 1

	if result == HitResult.Blocked then
		self._stopOutcome = ProjectileStepOutcome.Blocked
		return PostHitReaction.Stop
	end
	if self.HitCount > self.Definition.TargetPenetrationLimit then
		self._stopOutcome = ProjectileStepOutcome.HitPenetrationExhausted
		return PostHitReaction.Stop
	end

	return PostHitReaction.Continue
end

-- Starts this frame's move: sweeps the hitbox over it, and keeps it from reaching past a wall.
-- The hits themselves are delivered by the hit pass, then Settle finishes the move.
function Projectile.Advance(self: Projectile, dt: number, walls: WallCaster): ()
	local stepDt = math.min(dt, self.TimeLeft)
	local from = self.Position
	local to = self:Project(stepDt)
	local wallFraction = walls:FindFractionToWall(from, to)

	self._isAdvanced = true
	self._stepDt = stepDt
	self._stepFrom = from
	self._stepTo = to
	self._wallFraction = wallFraction
	self._stopOutcome = ProjectileStepOutcome.InFlight

	self.Hitbox:MoveTo(to)
	self.Hitbox:SetReachFraction(wallFraction or 1)
end

-- Finishes the move Advance started, given where the hit pass stopped the hitbox (nil if it
-- wasn't). Returns InFlight if the projectile keeps flying, otherwise why it ended.
function Projectile.Settle(self: Projectile, stopFraction: number?): ProjectileStepOutcome
	-- Nothing to settle for a projectile that was spawned after Advance ran.
	if not self._isAdvanced then
		return ProjectileStepOutcome.InFlight
	end
	self._isAdvanced = false

	local endFraction = 1
	local outcome: ProjectileStepOutcome = ProjectileStepOutcome.InFlight

	if stopFraction then
		endFraction = stopFraction
		outcome = self._stopOutcome
	elseif self._wallFraction then
		endFraction = self._wallFraction
		outcome = ProjectileStepOutcome.HitWall
	end

	self.Position = self._stepFrom + (self._stepTo - self._stepFrom) * endFraction
	self.Hitbox:Teleport(self.Position)
	self.TimeLeft -= self._stepDt

	if outcome == ProjectileStepOutcome.InFlight and self.TimeLeft <= 0 then
		outcome = ProjectileStepOutcome.Expired
	end

	return outcome
end

return Projectile
