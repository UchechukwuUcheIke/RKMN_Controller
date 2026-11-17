--!strict
local WallProbe = {}
WallProbe.__index = WallProbe
WallProbe.ClassName = "WallProbe"

local RKMNControllerFolder = script.Parent.Parent
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local CollisionTolerances = require(RKMNControllerFolder.CollisionTolerances)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local SlopeClassifier = require(script.Parent.SlopeClassifier)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

type CollisionBody = CollisionBody.CollisionBody
type CollisionTolerances = CollisionTolerances.CollisionTolerances
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type SlopeClassifier = SlopeClassifier.SlopeClassifier
type Direction = Direction.Direction

type WallProbeData = {
	_world: WorldRoot,
	_body: CollisionBody,
	_tolerances: CollisionTolerances,
	_slopeClassifier: SlopeClassifier,
	_raycastParams: RaycastParams,
}

type WallProbePrototype = typeof({__index = WallProbe})

export type WallProbe = typeof(setmetatable(
	{} :: WallProbeData,
	{} :: WallProbePrototype))

function WallProbe.new(
	world: WorldRoot,
	body: CollisionBody,
	tolerances: CollisionTolerances,
	slopeClassifier: SlopeClassifier,
	raycastParams: RaycastParams): WallProbe

	local data: WallProbeData = {
		_world = world,
		_body = body,
		_tolerances = tolerances,
		_slopeClassifier = slopeClassifier,
		_raycastParams = raycastParams,
	}

	return setmetatable(data, WallProbe)
end

function WallProbe.CheckContact(self: WallProbe, direction: Direction): DiagnosticCastRecord
	local halfWidth: number = self._body:GetHalfExtentAlongDirection(direction)
	local castDistance: number = self._tolerances.WallCheckDistance + self._tolerances.SkinWidth
	local origin: Vector3 = self._body:GetBodyCFrame().Position

	local rayOrigin: Vector3 = origin + direction * halfWidth
	local raycastResult: RaycastResult<BasePart>? = self._world:Raycast(rayOrigin, direction * castDistance, self._raycastParams)
	local hasContact: boolean = (raycastResult ~= nil) and not self._slopeClassifier:IsSurfaceWalkable(raycastResult.Normal)

	return DiagnosticCastRecord.fromRaycast(hasContact, rayOrigin, direction)
end

table.freeze(WallProbe)

return WallProbe
