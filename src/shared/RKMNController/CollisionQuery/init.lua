--!strict
local CollisionQuery = {}
CollisionQuery.__index = CollisionQuery

local RKMNControllerFolder = script.Parent
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local Direction = require(RKMNControllerFolder.Direction)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)

type CollisionConstants = CollisionConstants.CollisionConstants
type Direction = Direction.Direction
type SweepResolution = SweepResolution.SweepResolution
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type CastVolume = DiagnosticCastRecord.CastVolume

export type CollisionQueryData = {
    CurrentFloorPart: BasePart?,
	FloorNormal: Vector3,
	_world: WorldRoot,
	_characterModel: Model,
	_primaryPart: BasePart,
	_constants: CollisionConstants,
	_maxSlopeDot: number,
	_raycastParams: RaycastParams,
	IsGrounded: boolean,
}

export type CollisionQueryPrototype = typeof(CollisionQuery)

export type CollisionQuery = typeof(setmetatable(
	{} :: CollisionQueryData,
	{} :: CollisionQueryPrototype))

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
		IsGrounded = false,
		_world = world,
		_characterModel = characterModel,
		_primaryPart = primaryPart,
		_constants = collisionConstants,
		_maxSlopeDot = math.cos(math.rad(collisionConstants.MaxSlopeAngle)),
		_raycastParams = raycastParams,
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
    self.IsGrounded = false
	self.FloorNormal = Vector3.zero
end

function CollisionQuery._updateStateToOnGround(self:CollisionQuery, raycastResult : RaycastResult<BasePart>): ()
    self.IsGrounded = true
	self.FloorNormal = raycastResult.Normal

	local hitPart: BasePart = raycastResult.Instance :: BasePart
	self.CurrentFloorPart = hitPart
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

function CollisionQuery.CheckWallContact(
	self: CollisionQuery,
	direction: Direction): DiagnosticCastRecord

	local halfWidth: number = self._constants.HalfWidth
	local castDistance: number = self._constants.WallCheckDistance + self._constants.SkinWidth
	local origin: Vector3 = self._constants.HitboxCFrame.Position

	local rayOrigin: Vector3 = origin + direction * halfWidth
	local raycastResult: RaycastResult<BasePart>? = self._world:Raycast(rayOrigin, direction * castDistance, self._raycastParams)
	local hasContact: boolean = (raycastResult ~= nil) and not self:_isWalkable(raycastResult.Normal)

	local castRecord = DiagnosticCastRecord.fromRaycast(hasContact, rayOrigin, direction)
	return castRecord
end

function CollisionQuery._clampSweepResolution(self: CollisionQuery, castRecord: DiagnosticCastRecord, velocityDelta: Vector3, raycastResult: RaycastResult<BasePart>)
	local safeDistance = math.max(raycastResult.Distance - self._constants.SkinWidth, 0)
	local direction = velocityDelta.Unit
	local safeDelta = direction * safeDistance

	local hitFloor = self:_isWalkable(raycastResult.Normal)
	local hitWall = not hitFloor

	return SweepResolution.new(castRecord, safeDelta, hitFloor, hitWall)
end


function CollisionQuery.GetSweepResolution(self: CollisionQuery, velocityDelta: Vector3
): SweepResolution
    local origin = self._constants.HitboxCFrame
	local size = self._constants.HitboxSize
	local raycastResult: RaycastResult<BasePart>? = self._world:Blockcast(
		origin,
		size,
		velocityDelta,
		self._raycastParams
	)

	if not raycastResult then
		local castRecord = DiagnosticCastRecord.fromBlockcast(false, origin, size, velocityDelta)
		return SweepResolution.new(castRecord, velocityDelta)
	end

	local castRecord = DiagnosticCastRecord.fromBlockcast(true, origin, size, velocityDelta)
	local sweepResolution: SweepResolution = self:_clampSweepResolution(castRecord, velocityDelta, raycastResult)
	return sweepResolution
end

function CollisionQuery.Destroy(self: CollisionQuery)
	self.CurrentFloorPart = nil
	self._raycastParams.FilterDescendantsInstances = {}
end

table.freeze(CollisionQuery)

return CollisionQuery
