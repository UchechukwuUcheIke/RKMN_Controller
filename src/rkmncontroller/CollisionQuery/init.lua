--!strict
local CollisionQuery = {}
CollisionQuery.__index = CollisionQuery

local RKMNControllerFolder = script.Parent
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local Direction = require(RKMNControllerFolder.Direction)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)

type CollisionConstants = CollisionConstants.CollisionConstants
type Direction = Direction.Direction
type SweepResolution = SweepResolution.SweepResolution

type CollisionQueryData = {
    CurrentFloorPart: BasePart?,
	FloorNormal: Vector3,
	MovingPlatformDelta: CFrame,
	_world: WorldRoot,
	_lastFloorCFrame: CFrame?,
	_characterModel: Model,
	_primaryPart: BasePart,
	_constants: CollisionConstants,
	_maxSlopeDot: number,
	_raycastParams: RaycastParams,
	_isGrounded: boolean,
	_lastFloorPart: BasePart?
}

export type CollisionQuery = typeof(setmetatable(
	{} :: CollisionQueryData,
	CollisionQuery))

function createRaycastParams(characterModel: Model): RaycastParams
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { characterModel }

	return raycastParams
end

function CollisionQuery.new(world: WorldRoot, characterModel: Model, collisionConstants: CollisionConstants): CollisionQuery
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
		_constants = collisionConstants,
		_maxSlopeDot = math.cos(math.rad(collisionConstants.MaxSlopeAngle)),
		_raycastParams = raycastParams,
		_isGrounded = false,
		_lastFloorPart = nil,
	}, CollisionQuery) :: CollisionQuery

	return self
end

function CollisionQuery._isWalkable(self: CollisionQuery, normal: Vector3): boolean
	return normal:Dot(Vector3.yAxis) >= self._maxSlopeDot
end

function CollisionQuery._raycastToGround(self: CollisionQuery): RaycastResult<BasePart>?
	local origin = self._constants.FootCFrame
    local footSize = self._constants.FootSize
	local castDistance = self._constants.GroundCheckDistance + self._constants.SkinWidth

	local raycastResult: RaycastResult<BasePart>? = self._world:Blockcast(
		origin,
		footSize,
		Vector3.new(0, -castDistance, 0),
		self._raycastParams
	)

	return raycastResult
end

function CollisionQuery._updateStateToNotOnGround(self: CollisionQuery): ()
    self._isGrounded = false
	self.FloorNormal = Vector3.zero
	self.CurrentFloorPart = nil
	self.MovingPlatformDelta = CFrame.identity
	self._lastFloorPart = nil
	self._lastFloorCFrame = nil
end

function CollisionQuery._updateStateToOnGround(self:CollisionQuery, raycastResult : RaycastResult<BasePart>): ()
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

function CollisionQuery.UpdateState(self: CollisionQuery): ()
	local raycastResult: RaycastResult<BasePart>? = self:_raycastToGround()
	local canWalkOnGround: boolean = (raycastResult ~= nil) and self:_isWalkable(raycastResult.Normal)

	if not canWalkOnGround then
		self:_updateStateToNotOnGround()
		return
	end

	-- Putting this assert here to silence lua's strict typing; TODO: Look for a better fix
	assert(raycastResult ~= nil)
	raycastResult = raycastResult :: RaycastResult<BasePart>
    self:_updateStateToOnGround(raycastResult)
end

function CollisionQuery.IsGrounded(self: CollisionQuery): boolean
	return self._isGrounded
end

function CollisionQuery.CheckWallContact(
	self: CollisionQuery,
	direction: Direction): boolean

	local halfWidth: number = self._constants.HalfWidth
	local castDistance: number = self._constants.WallCheckDistance + self._constants.SkinWidth
	local origin: Vector3 = self._constants.HitboxCFrame.Position

	local rayOrigin: Vector3 = origin + direction * halfWidth
	local raycastResult: RaycastResult<BasePart>? = self._world:Raycast(rayOrigin, direction * castDistance, self._raycastParams)
	local hasContact: boolean = (raycastResult ~= nil) and not self:_isWalkable(raycastResult.Normal)
	
	return hasContact
end

function CollisionQuery._clampSweepResolution(self: CollisionQuery, velocityDelta: Vector3, raycastResult: RaycastResult<BasePart>)
	local safeDistance = math.max(raycastResult.Distance - self._constants.SkinWidth, 0)
	local direction = velocityDelta.Unit
	local safeDelta = direction * safeDistance

	local hitFloor = self:_isWalkable(raycastResult.Normal)
	local hitWall = not hitFloor

	return SweepResolution.new(safeDelta, hitFloor, hitWall)
end


function CollisionQuery.GetSweepResolution(self: CollisionQuery, velocityDelta: Vector3
): SweepResolution
	local distance = velocityDelta.Magnitude

	if distance <= 0 then
		return SweepResolution.new()
	end

    local origin = self._constants.HitboxCFrame
	local raycastResult: RaycastResult<BasePart>? = self._world:Blockcast(
		origin,
		self._constants.HitboxSize,
		velocityDelta,
		self._raycastParams
	)

	if not raycastResult then
		return SweepResolution.new(velocityDelta)
	end

	local sweepResolution: SweepResolution = self:_clampSweepResolution(velocityDelta, raycastResult)
	return sweepResolution
end

function CollisionQuery.Destroy(self: CollisionQuery)
	self.CurrentFloorPart = nil
	self._lastFloorPart = nil
	self._lastFloorCFrame = nil
	self._raycastParams.FilterDescendantsInstances = {}
end

table.freeze(CollisionQuery)

return CollisionQuery
