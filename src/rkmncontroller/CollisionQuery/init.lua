--!strict
local CollisionQuery = {}
CollisionQuery.__index = CollisionQuery

local MovementConstants = require(script.Parent.MovementConstants)
local Direction = require(script.Parent.Direction)
local SweepResolution = require(script.Parent.SweepResolution)

type MovementConstants = MovementConstants.MovementConstants
type Direction = Direction.Direction
type SweepResolution = SweepResolution.SweepResolution

export type CollisionQuery = typeof(setmetatable(
	{} :: {
	CurrentFloorPart: BasePart?,
	FloorNormal: Vector3,
	MovingPlatformDelta: CFrame,
	_world: WorldRoot,
	_lastFloorCFrame: CFrame?,
	_characterModel: Model,
	_primaryPart: BasePart,
	_constants: MovementConstants,
	_maxSlopeDot: number,
	_raycastParams: RaycastParams,
	_isGrounded: boolean,
	_lastFloorPart: BasePart?
	},
	{} :: typeof(CollisionQuery)))

function createRaycastParams(characterModel: Model): RaycastParams
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { characterModel }

	return raycastParams
end

function CollisionQuery.new(world: WorldRoot, characterModel: Model, movementConstants: MovementConstants): CollisionQuery
	local primaryPart = characterModel.PrimaryPart
	assert(primaryPart, "CharacterModel must have a PrimaryPart set before CollisionQuery.new()")

	local raycastParams: RaycastParams = createRaycastParams(characterModel)

	local self = setmetatable({
		CurrentFloorPart = nil,
		FloorNormal = Vector3.zero,
		MovingPlatformDelta = CFrame.identity,
		_world = world,
		_lastFloorCFrame = nil,
		_characterModel = characterModel,
		_primaryPart = primaryPart,
		_constants = movementConstants,
		_maxSlopeDot = math.cos(math.rad(movementConstants.MaxSlopeAngle)),
		_raycastParams = raycastParams,
		_isGrounded = false,
		_lastFloorPart = nil,
	}, CollisionQuery) :: CollisionQuery

	return self
end

function CollisionQuery._isWalkable(self: CollisionQuery, normal: Vector3): boolean
	return normal:Dot(Vector3.yAxis) >= self._maxSlopeDot
end

function CollisionQuery._raycastToGround(self: CollisionQuery, currentCFrame: CFrame): RaycastResult<BasePart>?
	local constants = self._constants
	local halfHeight = constants.HitboxSize.Y / 2

	local footSize = Vector3.new(constants.HitboxSize.X, 0.1, constants.HitboxSize.Z)
	local origin = currentCFrame.Position - Vector3.new(0, halfHeight - 0.05, 0)
	local castDistance = constants.GroundCheckDistance + constants.SkinWidth

	local raycastResult: RaycastResult<BasePart>? = self._world:Blockcast(
		CFrame.new(origin) * (currentCFrame.Rotation),
		footSize,
		Vector3.new(0, -castDistance, 0),
		self._raycastParams
	)

	return raycastResult
end

function CollisionQuery.UpdateState(self: CollisionQuery, currentCFrame: CFrame): ()
	local raycastResult: RaycastResult<BasePart>? = self:_raycastToGround(currentCFrame)
	local canWalkOnGround: boolean = (raycastResult ~= nil) and self:_isWalkable(raycastResult.Normal)

	if not canWalkOnGround then
		self._isGrounded = false
		self.FloorNormal = Vector3.zero
		self.CurrentFloorPart = nil
		self.MovingPlatformDelta = CFrame.identity
		self._lastFloorPart = nil
		self._lastFloorCFrame = nil

		return
	end

	-- Putting this assert here to silence lua's strict typing; TODO: Look for a better fix
	assert(raycastResult ~= nil)
	raycastResult = raycastResult :: RaycastResult<BasePart>
	self._isGrounded = true
	self.FloorNormal = raycastResult.Normal

	local hitPart: BasePart = raycastResult.Instance :: BasePart
	self.CurrentFloorPart = hitPart

	-- Moving platform delta: only meaningful if we were standing on this
	-- exact part last frame too. Otherwise (just landed / switched
	-- platforms) there's no valid "previous" pose to diff against.

	-- TODO: Not a fan of this function, will return to fix it up soon.
	if hitPart == self._lastFloorPart and self._lastFloorCFrame then
		self.MovingPlatformDelta = hitPart.CFrame * self._lastFloorCFrame:Inverse()
	else
		self.MovingPlatformDelta = CFrame.identity
	end

	self._lastFloorPart = hitPart
	self._lastFloorCFrame = hitPart.CFrame
end

function CollisionQuery.IsGrounded(self: CollisionQuery): boolean
	return self._isGrounded
end

function CollisionQuery.CheckWallContact(
	self: CollisionQuery,
	currentCFrame: CFrame,
	direction: Direction): boolean

	local constants = self._constants
	local halfWidth: number = constants.HitboxSize.X / 2
	local castDistance: number = constants.WallCheckDistance + constants.SkinWidth
	local origin: Vector3 = currentCFrame.Position

	local rayOrigin: Vector3 = origin + direction * halfWidth
	local raycastResult: RaycastResult<BasePart>? = self._world:Raycast(rayOrigin, direction * castDistance, self._raycastParams)
	local hasContact: boolean = (raycastResult ~= nil) and not self:_isWalkable(raycastResult.Normal)
	
	return hasContact
end

-- Core CCD method. Sweeps the character's full hitbox along velocityDelta
-- and returns the maximum safe movement, plus flags for what was struck.
-- PhysicsResolver is expected to call this with its intended per-frame
-- displacement and use the returned Vector3 instead of the raw delta.
function CollisionQuery.GetSweepResolution(
	self: CollisionQuery,
	startCFrame: CFrame,
	velocityDelta: Vector3
): SweepResolution
	local constants = self._constants

	if velocityDelta.Magnitude <= 0 then
		return SweepResolution.new()
	end

	local direction = velocityDelta.Unit
	local distance = velocityDelta.Magnitude

	local result = self._world:Blockcast(
		startCFrame,
		constants.HitboxSize,
		direction * distance,
		self._raycastParams
	)

	if not result then
		return SweepResolution.new(velocityDelta)
	end

	-- Clamp to the safe distance, backed off by SkinWidth so we don't end
	-- the frame exactly touching (and risk re-penetrating next frame due
	-- to float error).
	local safeDistance = math.max(result.Distance - constants.SkinWidth, 0)
	local safeDelta = direction * safeDistance

	local hitFloor = self:_isWalkable(result.Normal)
	local hitWall = not hitFloor

	return SweepResolution.new(safeDelta, hitFloor, hitWall)
end

function CollisionQuery.Destroy(self: CollisionQuery)
	self.CurrentFloorPart = nil
	self._lastFloorPart = nil
	self._lastFloorCFrame = nil
	self._raycastParams.FilterDescendantsInstances = {}
end

table.freeze(CollisionQuery)

return CollisionQuery