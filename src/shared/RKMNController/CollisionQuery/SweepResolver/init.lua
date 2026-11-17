--!strict
local SweepResolver = {}
SweepResolver.__index = SweepResolver
SweepResolver.ClassName = "SweepResolver"

local RKMNControllerFolder = script.Parent.Parent
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local CollisionTolerances = require(RKMNControllerFolder.CollisionTolerances)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local SurfaceHits = require(RKMNControllerFolder.SurfaceHits)
local SlopeClassifier = require(script.Parent.SlopeClassifier)

type CollisionBody = CollisionBody.CollisionBody
type CollisionTolerances = CollisionTolerances.CollisionTolerances
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type SweepResolution = SweepResolution.SweepResolution
type SlopeClassifier = SlopeClassifier.SlopeClassifier

const MIN_SWEEP_DISTANCE = 1e-6

type SweepResolverData = {
	_world: WorldRoot,
	_body: CollisionBody,
	_tolerances: CollisionTolerances,
	_slopeClassifier: SlopeClassifier,
	_raycastParams: RaycastParams,
}

type SweepResolverPrototype = typeof({__index = SweepResolver})

export type SweepResolver = typeof(setmetatable(
	{} :: SweepResolverData,
	{} :: SweepResolverPrototype))

function SweepResolver.new(
	world: WorldRoot,
	body: CollisionBody,
	tolerances: CollisionTolerances,
	slopeClassifier: SlopeClassifier,
	raycastParams: RaycastParams): SweepResolver

	local data: SweepResolverData = {
		_world = world,
		_body = body,
		_tolerances = tolerances,
		_slopeClassifier = slopeClassifier,
		_raycastParams = raycastParams,
	}

	return setmetatable(data, SweepResolver)
end

function SweepResolver._clampToHit(
	self: SweepResolver,
	castRecord: DiagnosticCastRecord,
	velocityDelta: Vector3,
	raycastResult: RaycastResult<BasePart>): SweepResolution

	local safeDistance = math.max(raycastResult.Distance - self._tolerances.SkinWidth, 0)
	local direction = velocityDelta.Unit
	local safeDelta = direction * safeDistance

	local normal = raycastResult.Normal
	local hitFloor = self._slopeClassifier:IsSurfaceWalkable(normal)
	local hitCeiling = velocityDelta.Y > 0 and self._slopeClassifier:IsSurfaceCeiling(normal)
	local hitWall = not hitFloor and not hitCeiling

	return SweepResolution.new(castRecord, safeDelta, SurfaceHits.new(hitFloor, hitWall, hitCeiling))
end

function SweepResolver._sweep(self: SweepResolver, velocityDelta: Vector3, originOffset: Vector3): SweepResolution
	local origin = self._body:GetBodyCFrame() + originOffset
	local size = self._body:GetBodySize()

	if velocityDelta.Magnitude < MIN_SWEEP_DISTANCE then
		local castRecord = DiagnosticCastRecord.fromBlockcast(false, origin, size, velocityDelta)
		return SweepResolution.new(castRecord, velocityDelta)
	end

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
	return self:_clampToHit(castRecord, velocityDelta, raycastResult)
end

local function mergeResolutions(vertical: SweepResolution, horizontal: SweepResolution): SweepResolution
	local v = vertical.SurfaceHits
	local h = horizontal.SurfaceHits
	local hits = SurfaceHits.new(
		v.HitFloor or h.HitFloor,
		v.HitWall or h.HitWall,
		v.HitCeiling or h.HitCeiling,
		v.HitLedge or h.HitLedge
	)

	local verticalCastWasTheOnlyHit = vertical.CastRecord.Success and not horizontal.CastRecord.Success
	local castRecord = if verticalCastWasTheOnlyHit then vertical.CastRecord else horizontal.CastRecord
	return SweepResolution.new(castRecord, vertical.SafeDelta + horizontal.SafeDelta, hits)
end

-- Diagonal casts stall against walls (the skin width is taken off the path, not the axis), so each axis gets its own cast.
function SweepResolver.Resolve(self: SweepResolver, velocityDelta: Vector3): SweepResolution
	local vertical: SweepResolution = self:_sweep(Vector3.new(0, velocityDelta.Y, 0), Vector3.zero)
	local horizontalDelta = Vector3.new(velocityDelta.X, 0, velocityDelta.Z)
	local horizontal: SweepResolution = self:_sweep(horizontalDelta, vertical.SafeDelta)
	return mergeResolutions(vertical, horizontal)
end

table.freeze(SweepResolver)

return SweepResolver
