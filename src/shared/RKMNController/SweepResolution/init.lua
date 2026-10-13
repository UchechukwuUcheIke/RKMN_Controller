local SweepResolution = {}
SweepResolution.__index = SweepResolution

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local SurfaceHits = require(RKMNControllerFolder.SurfaceHits)

type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord

type SurfaceHits = SurfaceHits.SurfaceHits

type SweepResolutionData = {
    CastRecord: DiagnosticCastRecord,
    SafeDelta: Vector3,
    SurfaceHits: SurfaceHits
}

type SweepResolutionPrototype = typeof(SweepResolution)

export type SweepResolution = typeof(setmetatable(
	{} :: SweepResolutionData,
    {} :: SweepResolutionPrototype))

function SweepResolution.new(castRecord: DiagnosticCastRecord?, safeDelta: Vector3?, surfaceHits: SurfaceHits?) : SweepResolution
    assert(castRecord)

    local self = setmetatable({
        CastRecord = castRecord or DiagnosticCastRecord.new(false, {Size = Vector3.zero, CFrame = CFrame.new()}),
	    SafeDelta = safeDelta or Vector3.zero,
        SurfaceHits = surfaceHits or SurfaceHits.new()
	    }, SweepResolution)

    return self
end

function SweepResolution.Destroy(self: SweepResolution): ()
    self.CastRecord:Destroy()
    self.SurfaceHits:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

return SweepResolution