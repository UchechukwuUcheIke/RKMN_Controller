--!strict
local GroundProbe = {}
GroundProbe.__index = GroundProbe
GroundProbe.ClassName = "GroundProbe"

local RKMNControllerFolder = script.Parent.Parent
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local CollisionTolerances = require(RKMNControllerFolder.CollisionTolerances)
local SlopeClassifier = require(script.Parent.SlopeClassifier)

type CollisionBody = CollisionBody.CollisionBody
type CollisionTolerances = CollisionTolerances.CollisionTolerances
type SlopeClassifier = SlopeClassifier.SlopeClassifier

type GroundProbeData = {
	CurrentFloorPart: BasePart?,
	FloorNormal: Vector3,
	_isGrounded: boolean,
	_world: WorldRoot,
	_body: CollisionBody,
	_tolerances: CollisionTolerances,
	_slopeClassifier: SlopeClassifier,
	_raycastParams: RaycastParams,
}

type GroundProbePrototype = typeof({__index = GroundProbe})

export type GroundProbe = typeof(setmetatable(
	{} :: GroundProbeData,
	{} :: GroundProbePrototype))

function GroundProbe.new(
	world: WorldRoot,
	body: CollisionBody,
	tolerances: CollisionTolerances,
	slopeClassifier: SlopeClassifier,
	raycastParams: RaycastParams): GroundProbe

	local data: GroundProbeData = {
		CurrentFloorPart = nil,
		FloorNormal = Vector3.zero,
		_isGrounded = false,
		_world = world,
		_body = body,
		_tolerances = tolerances,
		_slopeClassifier = slopeClassifier,
		_raycastParams = raycastParams,
	}

	return setmetatable(data, GroundProbe)
end

function GroundProbe._castDown(self: GroundProbe, offset: Vector3?): RaycastResult<BasePart>?
	local originOffset = offset or Vector3.zero
	local origin = self._body:GetFootCFrame() + originOffset
	local footSize = self._body:GetFootSize()
	local castDistance = self._tolerances.GroundCheckDistance + self._tolerances.SkinWidth

	return self._world:Blockcast(
		origin,
		footSize,
		Vector3.new(0, -castDistance, 0),
		self._raycastParams
	)
end

function GroundProbe._markNotGrounded(self: GroundProbe): ()
	self._isGrounded = false
	self.FloorNormal = Vector3.zero
end

function GroundProbe._markGrounded(self: GroundProbe, raycastResult: RaycastResult<BasePart>): ()
	self._isGrounded = true
	self.FloorNormal = raycastResult.Normal
	self.CurrentFloorPart = raycastResult.Instance :: BasePart
end

function GroundProbe.Update(self: GroundProbe): ()
	local raycastResult = self:_castDown()

	if raycastResult == nil or not self._slopeClassifier:IsSurfaceWalkable(raycastResult.Normal) then
		self:_markNotGrounded()
		return
	end

	self:_markGrounded(raycastResult)
end

function GroundProbe.IsGrounded(self: GroundProbe): boolean
	return self._isGrounded
end

function GroundProbe.HasWalkableGroundAt(self: GroundProbe, offset: Vector3): boolean
	local raycastResult = self:_castDown(offset)
	return raycastResult ~= nil and self._slopeClassifier:IsSurfaceWalkable(raycastResult.Normal)
end

function GroundProbe.Reset(self: GroundProbe): ()
	self.CurrentFloorPart = nil
end

table.freeze(GroundProbe)

return GroundProbe
