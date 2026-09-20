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
	}

type PhysicsResolverPrototype = typeof(PhysicsResolver)

export type PhysicsResolver = typeof(setmetatable(
	{} :: PhysicsResolverData,
	{} :: PhysicsResolverPrototype
))

local function validateCharacterModel(characterModel: Model)
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
	
	self:_disableRobloxPhysics()
	
	return (self :: PhysicsResolver)
end

function PhysicsResolver._disableRobloxPhysics(self: PhysicsResolver): ()
	self._rootPart.Anchored = true 

    for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        self._humanoid:SetStateEnabled(state, false)
    end
end

function PhysicsResolver.SetTargetXVelocity(self: PhysicsResolver, xVelocity: number, facingDirection: Direction)
	self.TargetXVelocity = xVelocity
	if facingDirection ~= Direction.None then
		self.FacingDirection = facingDirection
	end
end

function PhysicsResolver._applyHorizontalMovement(self: PhysicsResolver): ()
    self.Velocity = Vector3.new(self.TargetXVelocity, self.Velocity.Y, 0)
end

function PhysicsResolver._applyGravity(self: PhysicsResolver, dt: number): ()
	local gravity = self._movementStats.Gravity
    local currentYVelocity = self.Velocity.Y
	local newY = currentYVelocity - (gravity * dt)
	
	newY = math.max(newY, -self._movementStats.MaxFallSpeed)
	self.Velocity = Vector3.new(self.Velocity.X, newY, 0)
end

function PhysicsResolver._zeroXVelocity(self: PhysicsResolver): ()
    self.Velocity = Vector3.new(0, self.Velocity.Y, 0) 
end

function PhysicsResolver._zeroYVelocity(self: PhysicsResolver): ()
    self.Velocity = Vector3.new(self.Velocity.X, 0, 0) 
end

function PhysicsResolver._resolveVelocity(self: PhysicsResolver, sweepResolution: SweepResolution)
	if sweepResolution.hitWall then 
		self:_zeroXVelocity()
	end
	
	local hitFloorOrCeiling: boolean = sweepResolution.hitFloor
	if hitFloorOrCeiling then 
		self:_zeroYVelocity()
	end

    local currentCFrame = self._rootPart.CFrame
    local nextPos = currentCFrame.Position + sweepResolution.safeDelta
	local lookAtOffset = self.FacingDirection
	self._rootPart.CFrame = CFrame.lookAt(nextPos, nextPos + lookAtOffset)
end

function PhysicsResolver._sweepForCollisions(self: PhysicsResolver, dt: number): SweepResolution
	local currentCFrame = self._rootPart.CFrame
	local desiredDelta = self.Velocity * dt
	
	-- CollisionQuery handles the Blockcast/Spherecast math and returns a safe delta
	local sweepResolution: SweepResolution = self._collisionQuery:GetSweepResolution(currentCFrame, desiredDelta)

    return sweepResolution
end

function PhysicsResolver.Resolve(self: PhysicsResolver, dt: number): ()
	self:_applyHorizontalMovement()
	self._applyGravity(self, dt)
	local sweepResolution: SweepResolution = self._sweepForCollisions(self, dt)
    self:_resolveVelocity(sweepResolution)
end

function PhysicsResolver.Destroy(self: PhysicsResolver): ()
	self._rootPart.Anchored = false
end

return PhysicsResolver
