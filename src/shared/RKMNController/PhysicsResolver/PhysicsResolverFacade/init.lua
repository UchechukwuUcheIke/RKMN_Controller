--!strict
local PhysicsResolverFacade = {}
PhysicsResolverFacade.__index = PhysicsResolverFacade
PhysicsResolverFacade.ClassName = "PhysicsResolverFacade"

local PhysicsResolverFolder = script.Parent
local RKMNControllerFolder = PhysicsResolverFolder.Parent
local MovementStats = require(RKMNControllerFolder.MovementStats)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local CollisionQueryFacade = require(RKMNControllerFolder.CollisionQuery.CollisionQueryFacade)
local MotionState = require(PhysicsResolverFolder.MotionState)
local GravityIntegrator = require(PhysicsResolverFolder.GravityIntegrator)
local VelocityClipper = require(PhysicsResolverFolder.VelocityClipper)
local RootPartPlacer = require(PhysicsResolverFolder.RootPartPlacer)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

type MovementStats = MovementStats.MovementStats
type SweepResolution = SweepResolution.SweepResolution
type CollisionQueryFacade = CollisionQueryFacade.CollisionQueryFacade
type MotionState = MotionState.MotionState
type GravityIntegrator = GravityIntegrator.GravityIntegrator
type RootPartPlacer = RootPartPlacer.RootPartPlacer
type Direction = Direction.Direction

type PhysicsResolverFacadeData = {
	_movementStats: MovementStats,
	_collisionQuery: CollisionQueryFacade,
	_motion: MotionState,
	_gravity: GravityIntegrator,
	_placer: RootPartPlacer,
}

type PhysicsResolverFacadePrototype = typeof({__index = PhysicsResolverFacade})

export type PhysicsResolverFacade = typeof(setmetatable(
	{} :: PhysicsResolverFacadeData,
	{} :: PhysicsResolverFacadePrototype))

local function validateCharacterModel(characterModel: Model): ()
	assert(characterModel)
	assert(characterModel:FindFirstChild("HumanoidRootPart"))
	assert(characterModel:FindFirstChild("Humanoid"))
end

function PhysicsResolverFacade.new(
	characterModel: Model,
	movementStats: MovementStats,
	collisionQuery: CollisionQueryFacade): PhysicsResolverFacade

	validateCharacterModel(characterModel)

	local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart
	local data: PhysicsResolverFacadeData = {
		_movementStats = movementStats,
		_collisionQuery = collisionQuery,
		_motion = MotionState.new(),
		_gravity = GravityIntegrator.new(movementStats),
		_placer = RootPartPlacer.new(rootPart),
	}

	return setmetatable(data, PhysicsResolverFacade)
end

function PhysicsResolverFacade.GetVelocity(self: PhysicsResolverFacade): Vector3
	return self._motion.Velocity
end

function PhysicsResolverFacade.GetFacingDirection(self: PhysicsResolverFacade): Direction
	return self._motion.FacingDirection
end

function PhysicsResolverFacade.SetTargetXVelocity(self: PhysicsResolverFacade, xVelocity: number, facingDirection: Direction): ()
	self._motion:SetTargetXVelocity(xVelocity, facingDirection)
end

function PhysicsResolverFacade.MoveInDirection(self: PhysicsResolverFacade, direction: Direction, speed: number): ()
	self._motion:SetTargetXVelocity(direction.X * speed, direction)
end

function PhysicsResolverFacade.ApplyJumpImpulse(self: PhysicsResolverFacade): ()
	self._gravity:ClearRiseCut()
	self._motion:SetVelocityY(self._movementStats.JumpVelocity)
end

function PhysicsResolverFacade.CutRise(self: PhysicsResolverFacade): ()
	self._gravity:CutRise()
end

function PhysicsResolverFacade.SetFallSpeedOverride(self: PhysicsResolverFacade, speed: number?): ()
	self._gravity:SetFallSpeedOverride(speed)
end

function PhysicsResolverFacade.Resolve(self: PhysicsResolverFacade, dt: number): ()
	local motion = self._motion
	local previousYVelocity: number = motion.Velocity.Y

	motion:ApplyHorizontalTarget()
	self._gravity:Apply(motion, dt, self._collisionQuery:IsGrounded())

	local desiredDelta: Vector3 = motion:ComputeFrameDelta(previousYVelocity, dt)
	local sweepResolution: SweepResolution = self._collisionQuery:GetSweepResolution(desiredDelta)

	VelocityClipper.Clip(motion, sweepResolution)
	self._placer:Place(sweepResolution.SafeDelta, motion.FacingDirection)
end

function PhysicsResolverFacade.Destroy(self: PhysicsResolverFacade): ()
	self._placer:Release()
end

table.freeze(PhysicsResolverFacade)

return PhysicsResolverFacade
