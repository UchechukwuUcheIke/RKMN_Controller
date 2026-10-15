--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local DataFolder = RKMNCameraFolder.Data
local CameraZoneType = require(DataFolder.CameraZoneType)

local CameraZone = {}

export type ZoneType = CameraZoneType.CameraZoneType

export type SpatialBounds = {
    Center: Vector3,
    Size: Vector3
}

export type RailConstraints = {
    CameraOffset: Vector3,
    ClampMin: Vector3,
    ClampMax: Vector3
}

export type FixedViewport = {
    CFrame: CFrame
}

export type RailCameraZone = {
    Id: string,
    Type: ZoneType,
    SpatialBounds: SpatialBounds,
    RailConstraints: RailConstraints,
}

export type LockedCameraZone = {
    Id: string,
    Type: ZoneType,
    SpatialBounds: SpatialBounds,
    FixedViewport: FixedViewport
}

export type CameraZone = RailCameraZone | LockedCameraZone

function CameraZone.createRail(id: string, center: Vector3, size: Vector3, cameraOffset: Vector3): CameraZone
    local bounds: SpatialBounds = {
        Center = center,
        Size = size,
    }

    local halfSize = size / 2
    local railConstraints: RailConstraints = {
        CameraOffset = cameraOffset,
        ClampMin = center - halfSize,
        ClampMax = center + halfSize,
    }

    local zone : RailCameraZone = {
        Id = id,
        Type = CameraZoneType.Rail,
        SpatialBounds = bounds,
        RailConstraints = railConstraints
    }
    
    return zone
end

function CameraZone.createLocked(id: string, center: Vector3, size: Vector3, focusCFrame: CFrame): CameraZone
    local bounds: SpatialBounds = {
        Center = center,
        Size = size,
    }

    local viewport: FixedViewport = {
        CFrame = focusCFrame,
    }

    local zone: LockedCameraZone = {
        Id = id,
        Type = CameraZoneType.Locked,
        SpatialBounds = bounds,
        FixedViewport = viewport
    }
    
    return zone
end

return CameraZone

