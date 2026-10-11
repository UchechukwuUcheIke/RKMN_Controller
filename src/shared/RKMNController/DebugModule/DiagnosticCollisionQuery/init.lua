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
DiagnosticCollisionQuery.ClassName = "DiagnosticCollisionQuery"

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
	
	self.Snapshot.SweepResolution = sweepResolution

	return sweepResolution
end

function DiagnosticCollisionQuery.CheckWallContact(self: DiagnosticCollisionQuery, direction: Direction): DiagnosticCastRecord
	local super: CollisionQuery = (self :: any) :: CollisionQuery
	local wallContactHitResult: DiagnosticCastRecord = CollisionQuery.CheckWallContact(super, direction)

	self.Snapshot.WallContactCheck = wallContactHitResult

	return wallContactHitResult
end

function DiagnosticCollisionQuery.UpdateState(self: DiagnosticCollisionQuery)
	self.Snapshot:Clear()

	local super: CollisionQuery = (self :: any) :: CollisionQuery
	CollisionQuery.UpdateState(super)

	local constants: CollisionConstants = super._constants
	local castDistance: number = constants.GroundCheckDistance + constants.SkinWidth
	self.Snapshot.GroundContactCheck = DiagnosticCastRecord.fromBlockcast(
		super:IsGrounded(),
		constants:GetFootCFrame(),
		constants.FootSize,
		Vector3.new(0, -castDistance, 0)
	)
end

return DiagnosticCollisionQuery

