--!strict
local CollisionQuery = {}
CollisionQuery.__index = CollisionQuery
CollisionQuery.ClassName = "CollisionQuery"

local RKMNControllerFolder = script.Parent
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local Direction = require(RKMNControllerFolder.Direction)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local SurfaceHits = require(RKMNControllerFolder.SurfaceHits)

type CollisionConstants = CollisionConstants.CollisionConstants
type Direction = Direction.Direction
type SweepResolution = SweepResolution.SweepResolution
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type CastVolume = DiagnosticCastRecord.CastVolume

const LEDGE_BISECT_STEPS = 5
const MIN_LEDGE_CHECK_DISTANCE = 1e-4

export type CollisionQueryData = {
    CurrentFloorPart: BasePart?,
	FloorNormal: Vector3,
	LastSweepResolution: SweepResolution?,
	_isLedgeGuardEnabled: boolean,
	_world: WorldRoot,
	_characterModel: Model,
	_primaryPart: BasePart,
	_constants: CollisionConstants,
	_maxSlopeDot: number,
	_raycastParams: RaycastParams,
	_isGrounded: boolean,
}

export type CollisionQueryPrototype = typeof({__index = CollisionQuery})

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
		_isGrounded = false,
			LastSweepResolution = nil,
			_isLedgeGuardEnabled = false,
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

function CollisionQuery._raycastToGround(self: CollisionQuery, offset: Vector3?): RaycastResult<BasePart>?
	local origin = self._constants:GetFootCFrame() + (offset or Vector3.zero)
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

function CollisionQuery.IsGrounded(self: CollisionQuery): boolean
	return self._isGrounded
end

function CollisionQuery._updateStateToNotOnGround(self: CollisionQuery): ()
    self._isGrounded = false
	self.FloorNormal = Vector3.zero
end

function CollisionQuery._updateStateToOnGround(self:CollisionQuery, raycastResult : RaycastResult<BasePart>): ()
    self._isGrounded = true
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

	local halfWidth: number = self._constants:GetHalfExtentAlong(direction)
	local castDistance: number = self._constants.WallCheckDistance + self._constants.SkinWidth
	local origin: Vector3 = self._constants:GetHitboxCFrame().Position

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

	local normal = raycastResult.Normal
	local hitFloor = self:_isWalkable(normal)
	local hitCeiling = velocityDelta.Y > 0 and (-normal):Dot(Vector3.yAxis) >= self._maxSlopeDot
	local hitWall = not hitFloor and not hitCeiling

	return SweepResolution.new(castRecord, safeDelta, SurfaceHits.new(hitFloor, hitWall, hitCeiling))
end


function CollisionQuery.SetLedgeGuard(self: CollisionQuery, enabled: boolean): ()
	self._isLedgeGuardEnabled = enabled
end

function CollisionQuery._hasWalkableGroundAt(self: CollisionQuery, offset: Vector3): boolean
	local raycastResult: RaycastResult<BasePart>? = self:_raycastToGround(offset)
	return raycastResult ~= nil and self:_isWalkable(raycastResult.Normal)
end

function CollisionQuery._isLedgeGuardActive(self: CollisionQuery): boolean
	return self._isLedgeGuardEnabled and self._isGrounded
end

function CollisionQuery._findSupportedFraction(self: CollisionQuery, horizontal: Vector3): number
	local supportedFraction = 0
	local unsupportedFraction = 1

	for _ = 1, LEDGE_BISECT_STEPS do
		local midFraction = (supportedFraction + unsupportedFraction) / 2
		if self:_hasWalkableGroundAt(horizontal * midFraction) then
			supportedFraction = midFraction
		else
			unsupportedFraction = midFraction
		end
	end

	return supportedFraction
end

local function withLedgeHit(resolution: SweepResolution, clampedDelta: Vector3): SweepResolution
	local hits = resolution.SurfaceHits
	return SweepResolution.new(
		resolution.CastRecord,
		clampedDelta,
		SurfaceHits.new(hits.HitFloor, hits.HitWall, hits.HitCeiling, true)
	)
end

function CollisionQuery._applyLedgeGuard(self: CollisionQuery, resolution: SweepResolution): SweepResolution
	if not self:_isLedgeGuardActive() then
		return resolution
	end

	local safeDelta = resolution.SafeDelta
	local horizontal = Vector3.new(safeDelta.X, 0, safeDelta.Z)
	if horizontal.Magnitude < MIN_LEDGE_CHECK_DISTANCE or self:_hasWalkableGroundAt(horizontal) then
		return resolution
	end

	local fraction = self:_findSupportedFraction(horizontal)
	local clampedDelta = Vector3.new(safeDelta.X * fraction, safeDelta.Y, safeDelta.Z * fraction)
	return withLedgeHit(resolution, clampedDelta)
end

function CollisionQuery._sweep(self: CollisionQuery, velocityDelta: Vector3): SweepResolution
    local origin = self._constants:GetHitboxCFrame()
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

function CollisionQuery.GetSweepResolution(self: CollisionQuery, velocityDelta: Vector3): SweepResolution
	local resolution: SweepResolution = self:_applyLedgeGuard(self:_sweep(velocityDelta))
	self.LastSweepResolution = resolution
	return resolution
end

function CollisionQuery.Destroy(self: CollisionQuery)
	self.CurrentFloorPart = nil
	self._raycastParams.FilterDescendantsInstances = {}
end

table.freeze(CollisionQuery)

return CollisionQuery
