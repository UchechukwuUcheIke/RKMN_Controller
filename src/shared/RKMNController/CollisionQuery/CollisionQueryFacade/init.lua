--!strict
local CollisionQueryFacade = {}
CollisionQueryFacade.__index = CollisionQueryFacade
CollisionQueryFacade.ClassName = "CollisionQueryFacade"

local CollisionQueryFolder = script.Parent
local RKMNControllerFolder = CollisionQueryFolder.Parent
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local CollisionTolerances = require(RKMNControllerFolder.CollisionTolerances)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local SlopeClassifier = require(CollisionQueryFolder.SlopeClassifier)
local GroundProbe = require(CollisionQueryFolder.GroundProbe)
local WallProbe = require(CollisionQueryFolder.WallProbe)
local SweepResolver = require(CollisionQueryFolder.SweepResolver)
local LedgeGuard = require(CollisionQueryFolder.LedgeGuard)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

type CollisionBody = CollisionBody.CollisionBody
type CollisionTolerances = CollisionTolerances.CollisionTolerances
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type SweepResolution = SweepResolution.SweepResolution
type GroundProbe = GroundProbe.GroundProbe
type WallProbe = WallProbe.WallProbe
type SweepResolver = SweepResolver.SweepResolver
type LedgeGuard = LedgeGuard.LedgeGuard
type Direction = Direction.Direction

type CollisionQueryFacadeData = {
	_lastSweepResolution: SweepResolution?,
	_groundProbe: GroundProbe,
	_wallProbe: WallProbe,
	_sweepResolver: SweepResolver,
	_ledgeGuard: LedgeGuard,
	_raycastParams: RaycastParams,
}

type CollisionQueryFacadePrototype = typeof({__index = CollisionQueryFacade})

export type CollisionQueryFacade = typeof(setmetatable(
	{} :: CollisionQueryFacadeData,
	{} :: CollisionQueryFacadePrototype))

local function createRaycastParams(characterModel: Model): RaycastParams
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { characterModel }

	return raycastParams
end

function CollisionQueryFacade.new(
	world: WorldRoot,
	characterModel: Model,
	collisionBody: CollisionBody,
	collisionTolerances: CollisionTolerances): CollisionQueryFacade

	assert(characterModel.PrimaryPart, "CharacterModel must have a PrimaryPart set before CollisionQueryFacade.new()")

	local raycastParams = createRaycastParams(characterModel)
	local slopeClassifier = SlopeClassifier.new(collisionTolerances.MaxSlopeAngle)
	local groundProbe = GroundProbe.new(world, collisionBody, collisionTolerances, slopeClassifier, raycastParams)

	local data: CollisionQueryFacadeData = {
		_lastSweepResolution = nil,
		_groundProbe = groundProbe,
		_wallProbe = WallProbe.new(world, collisionBody, collisionTolerances, slopeClassifier, raycastParams),
		_sweepResolver = SweepResolver.new(world, collisionBody, collisionTolerances, slopeClassifier, raycastParams),
		_ledgeGuard = LedgeGuard.new(groundProbe),
		_raycastParams = raycastParams,
	}

	return setmetatable(data, CollisionQueryFacade)
end

function CollisionQueryFacade.UpdateState(self: CollisionQueryFacade): ()
	self._groundProbe:Update()
end

function CollisionQueryFacade.IsGrounded(self: CollisionQueryFacade): boolean
	return self._groundProbe:IsGrounded()
end

function CollisionQueryFacade.CheckWallContact(self: CollisionQueryFacade, direction: Direction): DiagnosticCastRecord
	return self._wallProbe:CheckContact(direction)
end

function CollisionQueryFacade.SetLedgeGuard(self: CollisionQueryFacade, enabled: boolean): ()
	self._ledgeGuard:SetEnabled(enabled)
end

function CollisionQueryFacade.GetSweepResolution(self: CollisionQueryFacade, velocityDelta: Vector3): SweepResolution
	local resolution: SweepResolution = self._ledgeGuard:Apply(self._sweepResolver:Resolve(velocityDelta))
	self._lastSweepResolution = resolution
	return resolution
end

function CollisionQueryFacade.GetLastSweepResolution(self: CollisionQueryFacade): SweepResolution?
	return self._lastSweepResolution
end

function CollisionQueryFacade.Destroy(self: CollisionQueryFacade): ()
	self._groundProbe:Reset()
	self._raycastParams.FilterDescendantsInstances = {}
end

table.freeze(CollisionQueryFacade)

return CollisionQueryFacade
