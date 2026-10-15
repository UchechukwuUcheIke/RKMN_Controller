--!strict
local PhysicsResolver = {}
PhysicsResolver.__index = PhysicsResolver

local RKMNControllerFolder = script.Parent
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local MovementStats = require(RKMNControllerFolder.MovementStats)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local Direction = require(RKMNControllerFolder.Direction)

type MovementStats = MovementStats.MovementStats
type CollisionQuery = CollisionQuery.CollisionQuery
type Direction = Direction.Direction
type SweepResolution = SweepResolution.SweepResolution

type PhysicsResolverData = {
		_character: Model,
		_rootPart: BasePart,
        _humanoid: Humanoid,
        _movementStats: MovementStats,
        _collisionQuery: CollisionQuery,
        Velocity: Vector3,
        -- I'll bite for now
        FacingDirection: Direction,
        TargetXVelocity: number,
        _fallSpeedOverride: number?,
        _isRiseCut: boolean,
	}

type PhysicsResolverPrototype = typeof(PhysicsResolver)

export type PhysicsResolver = typeof(setmetatable(
	{} :: PhysicsResolverData,
	{} :: PhysicsResolverPrototype
))

local function validateCharacterModel(characterModel: Model): ()
    assert(characterModel)
    assert(characterModel:FindFirstChild("HumanoidRootPart"))
    assert(characterModel:FindFirstChild("Humanoid"))
end

function PhysicsResolver.new(characterModel: Model, movementStats: MovementStats, collisionQuery: CollisionQuery): PhysicsResolver
    validateCharacterModel(characterModel)

	local self = setmetatable({}, PhysicsResolver)
    self._character = characterModel
    self._rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart
    self._humanoid = characterModel:FindFirstChild("Humanoid") :: Humanoid
    self._movementStats = movementStats
    self._collisionQuery = collisionQuery
    self.Velocity = Vector3.zero
    self.FacingDirection = Direction.Right
    self.TargetXVelocity = 0
    self._isRiseCut = false
	
	self:_disableRobloxPhysics()
	
	return (self :: PhysicsResolver)
end

function PhysicsResolver._disableRobloxPhysics(self: PhysicsResolver): ()
	self._rootPart.Anchored = true
end

function PhysicsResolver.SetTargetXVelocity(self: PhysicsResolver, xVelocity: number, facingDirection: Direction)
	self.TargetXVelocity = xVelocity
	if facingDirection ~= Direction.None then
		self.FacingDirection = facingDirection
	end
end

function PhysicsResolver.MoveInDirection(self: PhysicsResolver, direction: Direction, speed: number): ()
	self:SetTargetXVelocity(direction.X * speed, direction)
end

function PhysicsResolver.ApplyJumpImpulse(self: PhysicsResolver): ()
	self._isRiseCut = false
	self.Velocity = Vector3.new(self.Velocity.X, self._movementStats.JumpVelocity, 0)
end

function PhysicsResolver.CutRise(self: PhysicsResolver): ()
	self._isRiseCut = true
end

function PhysicsResolver._applyHorizontalMovement(self: PhysicsResolver): ()
    self.Velocity = Vector3.new(self.TargetXVelocity, self.Velocity.Y, 0)
end

function PhysicsResolver.SetFallSpeedOverride(self: PhysicsResolver, speed: number?): ()
	self._fallSpeedOverride = speed
end

function PhysicsResolver._getGravity(self: PhysicsResolver): number
	local stats = self._movementStats
	if self.Velocity.Y <= 0 then
		return stats.FallGravity
	end

	return if self._isRiseCut then stats.CutGravity else stats.RiseGravity
end

function PhysicsResolver._applyGravity(self: PhysicsResolver, dt: number): ()
	if self.Velocity.Y <= 0 and self._collisionQuery:IsGrounded() then
		self:_zeroYVelocity()
		return
	end

	local fallSpeedCap: number = self._fallSpeedOverride or self._movementStats.FallSpeed
	local newY = math.max(self.Velocity.Y - self:_getGravity() * dt, -fallSpeedCap)
	self.Velocity = Vector3.new(self.Velocity.X, newY, 0)
end

function PhysicsResolver._zeroXVelocity(self: PhysicsResolver): ()
    self.Velocity = Vector3.new(0, self.Velocity.Y, 0) 
end

function PhysicsResolver._zeroYVelocity(self: PhysicsResolver): ()
    self.Velocity = Vector3.new(self.Velocity.X, 0, 0) 
end

function PhysicsResolver._resolveVelocity(self: PhysicsResolver, sweepResolution: SweepResolution): ()
	local hits = sweepResolution.SurfaceHits
	if hits.HitWall then
		self:_zeroXVelocity()
	end
	
	local hitFloorOrCeiling: boolean = hits.HitFloor or hits.HitCeiling
	if hitFloorOrCeiling then
		self:_zeroYVelocity()
	end
end

function PhysicsResolver._resolvePosition(self: PhysicsResolver, sweepResolution: SweepResolution)
	self:_resolveVelocity(sweepResolution)

    local currentCFrame = self._rootPart.CFrame
    local nextPos = currentCFrame.Position + sweepResolution.SafeDelta
	local lookAtOffset = self.FacingDirection
	self._rootPart.CFrame = CFrame.lookAt(nextPos, nextPos + lookAtOffset)
end

-- Averaging the start and end Y velocity keeps jump height independent of framerate.
function PhysicsResolver._sweepForCollisions(self: PhysicsResolver, dt: number, previousYVelocity: number): SweepResolution
	local averageYVelocity = (previousYVelocity + self.Velocity.Y) / 2
	local desiredDelta = Vector3.new(self.Velocity.X, averageYVelocity, 0) * dt
	local sweepResolution: SweepResolution = self._collisionQuery:GetSweepResolution(desiredDelta)

    return sweepResolution
end

function PhysicsResolver.Resolve(self: PhysicsResolver, dt: number): ()
	local previousYVelocity: number = self.Velocity.Y
	self:_applyHorizontalMovement()
	self:_applyGravity(dt)
	local sweepResolution: SweepResolution = self:_sweepForCollisions(dt, previousYVelocity)
    self:_resolvePosition(sweepResolution)
end

function PhysicsResolver.Destroy(self: PhysicsResolver): ()
	self._rootPart.Anchored = false
end

return PhysicsResolver
