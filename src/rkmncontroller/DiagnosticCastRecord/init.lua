--!strict
local DiagnosticCastRecord = {}
DiagnosticCastRecord.__index = DiagnosticCastRecord

export type CastVolume = {
    Size: Vector3,
    CFrame: CFrame
}

type DiagnosticCastRecordData = {
    Success: boolean,
    CastVolume: CastVolume
}

type DiagnosticCastRecordPrototype = typeof(DiagnosticCastRecord)

export type DiagnosticCastRecord = typeof(setmetatable(
    {} :: DiagnosticCastRecordData,
    {} :: DiagnosticCastRecordPrototype
))

function DiagnosticCastRecord.new(success: boolean, castVolume): DiagnosticCastRecord
    local data = {
        Success = success,
        CastVolume = castVolume,
    } :: DiagnosticCastRecordData

    local self = setmetatable(data, DiagnosticCastRecord)

    return self
end

local function getCastVolumeFromOriginAndDirection(origin: Vector3, direction: Vector3): CastVolume
    local endPosition: Vector3 = origin + direction
    local distance = (origin - endPosition).Magnitude
    local size: Vector3 = Vector3.new(0.2, 0.2, distance)
    local cframe: CFrame = CFrame.lookAt(origin, endPosition) * CFrame.new(0, 0, -distance / 2)

    local castVolume: CastVolume = {
        Size = size,
        CFrame = cframe,
    }

    return castVolume
end


function DiagnosticCastRecord.fromRaycast(success: boolean, origin: Vector3, direction: Vector3): DiagnosticCastRecord
    local castVolume: CastVolume = getCastVolumeFromOriginAndDirection(origin, direction)
    return DiagnosticCastRecord.new(success, castVolume)
end


table.freeze(DiagnosticCastRecord)

return DiagnosticCastRecord