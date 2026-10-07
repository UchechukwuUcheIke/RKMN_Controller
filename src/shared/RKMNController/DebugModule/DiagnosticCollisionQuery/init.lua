--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)

local DebugFolder = script.Parent
local DebugDataFolder = DebugFolder.Data
local CollisionQuerySnapshot = require(DebugDataFolder.CollisionQuerySnapshot)
local Direction = require(RKMNControllerFolder.Direction)
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)

type SweepResolution = SweepResolution.SweepResolution
type Direction = Direction.Direction
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type CollisionQueryData = CollisionQuery.CollisionQueryData
type CollisionQueryPrototype = CollisionQuery.CollisionQueryPrototype
type CollisionQuerySnapshot = CollisionQuerySnapshot.CollisionQuerySnapshot
type CollisionQuery = CollisionQuery.CollisionQuery
type CollisionConstants = CollisionConstants.CollisionConstants

local DiagnosticCollisionQuery = setmetatable({}, { __index = CollisionQuery })
DiagnosticCollisionQuery.__index = DiagnosticCollisionQuery

type DiagnosticCollisionQueryData = CollisionQueryData & {
	Snapshot: CollisionQuerySnapshot,
}

type DiagnosticCollisionQueryPrototype = CollisionQueryPrototype & typeof(DiagnosticCollisionQuery)

export type DiagnosticCollisionQuery = typeof(setmetatable(
    {} :: DiagnosticCollisionQueryData,
    {} :: DiagnosticCollisionQueryPrototype))

function DiagnosticCollisionQuery.new(world: WorldRoot, characterModel: Model, collisionConstants: CollisionConstants): DiagnosticCollisionQuery
	local self = CollisionQuery.new(world, characterModel, collisionConstants) :: any
	setmetatable(self, DiagnosticCollisionQuery)
	self.IsRecording = false
	self.Snapshot = CollisionQuerySnapshot.new()
	
	return self :: DiagnosticCollisionQuery
end

function DiagnosticCollisionQuery.GetSweepResolution(self: DiagnosticCollisionQuery, desiredDelta: Vector3): SweepResolution
	local super: CollisionQuery = (self :: any) :: CollisionQuery
	local sweepResolution: SweepResolution = CollisionQuery.GetSweepResolution(super, desiredDelta)
	
	if self.IsRecording then
		local sweepHitResult = sweepResolution.HitResult
		self.Snapshot.SweepResolution = sweepHitResult
	end
	
	return sweepResolution
end

function DiagnosticCollisionQuery.GetWallContact(self: DiagnosticCollisionQuery, direction: Direction): DiagnosticCastRecord
	local super: CollisionQuery = (self :: any) :: CollisionQuery
	local wallContactHitResult: DiagnosticCastRecord = CollisionQuery.CheckWallContact(super, direction)

	if self.IsRecording then
		self.Snapshot.WallContactCheck = wallContactHitResult
	end

	return wallContactHitResult
end

function DiagnosticCollisionQuery.Update(self: DiagnosticCollisionQuery)
	self.Snapshot:Clear()

	local super: CollisionQuery = (self :: any) :: CollisionQuery
	local raycastResult: RaycastResult<BasePart>? = CollisionQuery._raycastToGround(super)
	local canWalkOnGround: boolean = (raycastResult ~= nil) and CollisionQuery._isWalkable(super, raycastResult.Normal)

	if not canWalkOnGround then
		CollisionQuery._updateStateToNotOnGround(super)
		return
	end

	-- Putting this assert here to silence lua's strict typing; TODO: Look for a better fix
	assert(raycastResult ~= nil)
	raycastResult = raycastResult :: RaycastResult<BasePart>
    CollisionQuery._updateStateToOnGround(super, raycastResult)
end

return DiagnosticCollisionQuery

