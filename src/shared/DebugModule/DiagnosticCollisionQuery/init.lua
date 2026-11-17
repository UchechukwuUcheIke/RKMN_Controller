--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local CollisionQueryFacade = require(RKMNControllerFolder.CollisionQuery.CollisionQueryFacade)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local CollisionTolerances = require(RKMNControllerFolder.CollisionTolerances)

local DebugFolder = script.Parent
local CollisionQuerySnapshot = require(DebugFolder.Data.CollisionQuerySnapshot)
local Direction = require(ReplicatedStorage.Data.Direction)

type SweepResolution = SweepResolution.SweepResolution
type Direction = Direction.Direction
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type CollisionQueryFacade = CollisionQueryFacade.CollisionQueryFacade
type CollisionQuerySnapshot = CollisionQuerySnapshot.CollisionQuerySnapshot
type CollisionBody = CollisionBody.CollisionBody
type CollisionTolerances = CollisionTolerances.CollisionTolerances

-- Decorates a CollisionQueryFacade: forwards every call to it and records what was queried into Snapshot.
local DiagnosticCollisionQuery = {}
DiagnosticCollisionQuery.__index = DiagnosticCollisionQuery
DiagnosticCollisionQuery.ClassName = "DiagnosticCollisionQuery"

type DiagnosticCollisionQueryData = {
	Snapshot: CollisionQuerySnapshot,
	_inner: CollisionQueryFacade,
	_body: CollisionBody,
	_tolerances: CollisionTolerances,
}

type DiagnosticCollisionQueryPrototype = typeof({__index = DiagnosticCollisionQuery})

export type DiagnosticCollisionQuery = typeof(setmetatable(
	{} :: DiagnosticCollisionQueryData,
	{} :: DiagnosticCollisionQueryPrototype))

function DiagnosticCollisionQuery.new(
	inner: CollisionQueryFacade,
	collisionBody: CollisionBody,
	collisionTolerances: CollisionTolerances): DiagnosticCollisionQuery

	local data: DiagnosticCollisionQueryData = {
		Snapshot = CollisionQuerySnapshot.new(),
		_inner = inner,
		_body = collisionBody,
		_tolerances = collisionTolerances,
	}

	return setmetatable(data, DiagnosticCollisionQuery)
end

function DiagnosticCollisionQuery.UpdateState(self: DiagnosticCollisionQuery): ()
	self.Snapshot:Clear()
	self._inner:UpdateState()

	local castDistance: number = self._tolerances.GroundCheckDistance + self._tolerances.SkinWidth
	self.Snapshot.GroundContactCheck = DiagnosticCastRecord.fromBlockcast(
		self._inner:IsGrounded(),
		self._body:GetFootCFrame(),
		self._body:GetFootSize(),
		Vector3.new(0, -castDistance, 0)
	)
end

function DiagnosticCollisionQuery.IsGrounded(self: DiagnosticCollisionQuery): boolean
	return self._inner:IsGrounded()
end

function DiagnosticCollisionQuery.CheckWallContact(self: DiagnosticCollisionQuery, direction: Direction): DiagnosticCastRecord
	local wallContactHitResult: DiagnosticCastRecord = self._inner:CheckWallContact(direction)
	self.Snapshot.WallContactCheck = wallContactHitResult

	return wallContactHitResult
end

function DiagnosticCollisionQuery.SetLedgeGuard(self: DiagnosticCollisionQuery, enabled: boolean): ()
	self._inner:SetLedgeGuard(enabled)
end

function DiagnosticCollisionQuery.GetSweepResolution(self: DiagnosticCollisionQuery, desiredDelta: Vector3): SweepResolution
	local sweepResolution: SweepResolution = self._inner:GetSweepResolution(desiredDelta)
	self.Snapshot.SweepResolution = sweepResolution

	return sweepResolution
end

function DiagnosticCollisionQuery.GetLastSweepResolution(self: DiagnosticCollisionQuery): SweepResolution?
	return self._inner:GetLastSweepResolution()
end

function DiagnosticCollisionQuery.Destroy(self: DiagnosticCollisionQuery): ()
	self._inner:Destroy()
end

table.freeze(DiagnosticCollisionQuery)

return DiagnosticCollisionQuery
