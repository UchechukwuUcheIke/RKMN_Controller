local SweepResolution = {}
SweepResolution.__index = SweepResolution

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)

type DiagnosticCastRecord = DiagnosticCastRecord.DiagnosticCastRecord

type SweepResolutionData = {
    CastRecord: DiagnosticCastRecord,
    SafeDelta: Vector3,
    HitFloor: boolean,
    HitWall: boolean,
}

type SweepResolutionPrototype = typeof(SweepResolution)

export type SweepResolution = typeof(setmetatable(
	{} :: SweepResolutionData,
    {} :: SweepResolutionPrototype))

function SweepResolution.new(castRecord: DiagnosticCastRecord, safeDelta: Vector3?, hitFloor: boolean?, hitWall: boolean?) : SweepResolution
    assert(castRecord)

    local self = setmetatable({
        CastRecord = castRecord,
	    SafeDelta = safeDelta or Vector3.zero,
        HitFloor = hitFloor or false,
        HitWall = hitWall or false

	    }, SweepResolution)

    return self
end

function SweepResolution.Destroy(self: SweepResolution): ()
    self.CastRecord:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

return SweepResolution