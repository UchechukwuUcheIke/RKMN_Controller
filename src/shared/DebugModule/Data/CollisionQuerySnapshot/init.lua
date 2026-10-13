local CollisionQuerySnapshot = {}
CollisionQuerySnapshot.__index = CollisionQuerySnapshot

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)

type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord
type SweepResolution = SweepResolution.SweepResolution

type CollisionQuerySnapshotData = {
    GroundContactCheck: DiagnosticCastRecord?,
	WallContactCheck: DiagnosticCastRecord?,
	SweepResolution: SweepResolution?
}

type CollisionQuerySnapshotPrototype = typeof(CollisionQuerySnapshot)

export type CollisionQuerySnapshot = typeof(
    setmetatable(
        {} :: CollisionQuerySnapshotData, 
        {} :: CollisionQuerySnapshotPrototype
    )
)

function CollisionQuerySnapshot.new(): CollisionQuerySnapshot
	local self = setmetatable({}, CollisionQuerySnapshot)
	self.GroundCheck = nil
	self.WallContact = nil
	
	self.SweepResolution = nil
	
	return self
end

function CollisionQuerySnapshot.Clear(self: CollisionQuerySnapshot): ()
    self.GroundContactCheck = nil
    self.WallContactCheck = nil
    self.SweepResolution = nil
end

function CollisionQuerySnapshot.Destroy(self: CollisionQuerySnapshot): ()
    if self.GroundContactCheck then
        self.GroundContactCheck:Destroy()
    end

    if self.WallContactCheck then
        self.WallContactCheck:Destroy()
    end

    if self.SweepResolution then
        self.SweepResolution:Destroy()
    end

    self:Clear()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(CollisionQuerySnapshot)

return CollisionQuerySnapshot