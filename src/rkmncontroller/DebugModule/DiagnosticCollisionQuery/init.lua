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

type SweepResolution = SweepResolution.SweepResolution
type Direction = Direction.Direction
type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type CollisionQueryData = CollisionQuery.CollisionQueryData
type CollisionQueryPrototype = CollisionQuery.CollisionQueryPrototype
type CollisionQuerySnapshot = CollisionQuerySnapshot.CollisionQuerySnapshot
type CollisionQuery = CollisionQuery.CollisionQuery

local DiagnosticCollisionQuery = setmetatable({}, { __index = CollisionQuery })
DiagnosticCollisionQuery.__index = DiagnosticCollisionQuery

type DiagnosticCollisionQueryData = CollisionQueryData & {
	LastSnapshot: CollisionQuerySnapshot,
	IsRecording: boolean,
}

type DiagnosticCollisionQueryPrototype = CollisionQueryPrototype & typeof(DiagnosticCollisionQuery)

export type DiagnosticCollisionQuery = typeof(setmetatable(
    {} :: DiagnosticCollisionQueryData,
    {} :: DiagnosticCollisionQueryPrototype))

function DiagnosticCollisionQuery.new(collisionQuery: DiagnosticCollisionQuery): DiagnosticCollisionQuery
	local self = CollisionQuery.new()
	setmetatable(self, DiagnosticCollisionQuery)
	self.IsRecording = false
	self.LastSnapshot = CollisionQuerySnapshot.new()
	
	return self :: DiagnosticCollisionQuery
end

function DiagnosticCollisionQuery.GetSweepResolution(self: DiagnosticCollisionQuery, desiredDelta: Vector3): SweepResolution
	local sweepResolution: SweepResolution = CollisionQuery.GetSweepResolution(self :: CollisionQuery, desiredDelta)
	
	if self.IsRecording then
		local sweepHitResult = sweepResolution.HitResult
		self.LastSnapshot.SweepResolution = sweepHitResult
	end
	
	return sweepResolution
end

function DiagnosticCollisionQuery.GetWallContact(self: DiagnosticCollisionQuery, direction: Direction): DiagnosticCastRecord
	local wallContactHitResult: DiagnosticCastRecord = CollisionQuery.CheckWallContact((self :: any):: CollisionQuery, direction)

	if self.IsRecording then
		self.LastSnapshot.WallContactCheck = wallContactHitResult
	end

	return wallContactHitResult
end

function DiagnosticCollisionQuery.Update()
	self.LastSnapshot:Clear()
	-- do more update shit
end

return DiagnosticCollisionQuery

