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

	_stopOutcome: ProjectileStepOutcome,
	_isAdvanced: boolean,
	_stepDt: number,
	_stepFromPosition: Vector2,
	_stepToPosition: Vector2,
	_wallFraction: number?,
}

type ProjectilePrototype = typeof(Projectile)

export type Projectile = typeof(setmetatable(
	{} :: ProjectileData,
	{} :: ProjectilePrototype
))

function Projectile.new(
	definition: ProjectileDefinition,
	ownerId: number,
	team: Team.Team,
	position: Vector2,
	direction: Direction
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
		OnHit = function(_: Hurtbox, result: HitResult): PostHitReaction
			return projectile:_reactToHit(result)
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

		_stopOutcome = ProjectileStepOutcome.InFlight :: ProjectileStepOutcome,
		_isAdvanced = false,
		_stepDt = 0,
		_stepFromPosition = position,
		_stepToPosition = position,
		_wallFraction = nil,
	}

	projectile = setmetatable(data, Projectile)
	return projectile
end

function Projectile.Project(self: Projectile, dt: number): Vector2
	return self.Position + self.Velocity * dt
end

function Projectile._reactToHit(self: Projectile, result: HitResult): PostHitReaction
	if result == HitResult.Ignored then
		return PostHitReaction.Continue :: PostHitReaction
	end

	self.HitCount += 1

	if result == HitResult.Blocked then
		self._stopOutcome = ProjectileStepOutcome.Blocked :: ProjectileStepOutcome
		return PostHitReaction.Stop :: PostHitReaction
	end

	if self.HitCount > self.Definition.TargetPenetrationLimit then
		self._stopOutcome = ProjectileStepOutcome.HitPenetrationExhausted :: ProjectileStepOutcome
		return PostHitReaction.Stop :: PostHitReaction
	end

	return PostHitReaction.Continue :: PostHitReaction
end

function Projectile.Advance(self: Projectile, dt: number, walls: WallCaster): ()
	local stepDt = math.min(dt, self.TimeLeft)
	local currentPosition = self.Position
	local nextPosition = self:Project(stepDt)
	local wallFraction = walls:FindFractionToWall(currentPosition, nextPosition)

	self._isAdvanced = true
	self._stepDt = stepDt
	self._stepFromPosition = currentPosition
	self._stepToPosition = nextPosition
	self._wallFraction = wallFraction
	self._stopOutcome = ProjectileStepOutcome.InFlight :: ProjectileStepOutcome

	self.Hitbox:MoveTo(nextPosition)
	self.Hitbox:SetReachFraction(wallFraction or 1)
end


function Projectile.CommitMove(self: Projectile, stopFraction: number?): ProjectileStepOutcome
	if not self._isAdvanced then
		return ProjectileStepOutcome.InFlight :: ProjectileStepOutcome
	end
	self._isAdvanced = false

	local endFraction = 1
	local outcome: ProjectileStepOutcome = ProjectileStepOutcome.InFlight :: ProjectileStepOutcome

	if stopFraction then
		endFraction = stopFraction
		outcome = self._stopOutcome
	elseif self._wallFraction then
		endFraction = self._wallFraction
		outcome = ProjectileStepOutcome.HitWall :: ProjectileStepOutcome
	end

	self.Position = self._stepFromPosition + (self._stepToPosition - self._stepFromPosition) * endFraction
	self.Hitbox:Teleport(self.Position)
	self.TimeLeft -= self._stepDt

	local hasProjectileExpired = outcome == ProjectileStepOutcome.InFlight and self.TimeLeft <= 0
	if hasProjectileExpired then
		outcome = ProjectileStepOutcome.Expired :: ProjectileStepOutcome
	end

	return outcome
end

return Projectile
