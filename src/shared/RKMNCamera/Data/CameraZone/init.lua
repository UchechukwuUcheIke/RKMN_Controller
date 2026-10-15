--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local DataFolder = RKMNCameraFolder.Data
local CameraZoneType = require(DataFolder.CameraZoneType)
local VerticalFollow = require(DataFolder.VerticalFollow)

local CameraZone = {}

type VerticalFollow = VerticalFollow.VerticalFollow

export type ZoneType = CameraZoneType.CameraZoneType

export type SpatialBounds = {
    Center: Vector3,
    Size: Vector3
}

export type RailConstraints = {
    CameraOffset: Vector3,
    VerticalFollow: VerticalFollow,
	DeadzoneFraction: number,
	GroundedScrollSpeed: number,
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

export type RailOptions = {
    VerticalFollow: VerticalFollow?,
    DeadzoneFraction: number?,
    GroundedScrollSpeed: number?,
}

const DEFAULT_VERTICAL_FOLLOW: VerticalFollow = VerticalFollow.Tracking
const DEFAULT_DEADZONE_FRACTION = 0.3
const DEFAULT_GROUNDED_SCROLL_SPEED = 10

function CameraZone.createRail(
    id: string,
    center: Vector3,
    size: Vector3,
    cameraOffset: Vector3,
    options: RailOptions?
): RailCameraZone
    local bounds: SpatialBounds = {
        Center = center,
        Size = size,
    }

    -- Rail cameras look down -Z, so the offset must put the camera in front of the player.
    assert(cameraOffset.Z > 0, `Rail zone {id} needs a CameraOffset with positive Z`)
    local resolvedOptions: RailOptions = options or {}
    local railConstraints: RailConstraints = {
        CameraOffset = cameraOffset,
        VerticalFollow = resolvedOptions.VerticalFollow or DEFAULT_VERTICAL_FOLLOW,
        DeadzoneFraction = resolvedOptions.DeadzoneFraction or DEFAULT_DEADZONE_FRACTION,
        GroundedScrollSpeed = resolvedOptions.GroundedScrollSpeed or DEFAULT_GROUNDED_SCROLL_SPEED,
    }

    local zone : RailCameraZone = {
        Id = id,
        Type = CameraZoneType.Rail,
        SpatialBounds = bounds,
        RailConstraints = railConstraints
    }
    
    return zone
end

function CameraZone.createLocked(id: string, center: Vector3, size: Vector3, focusCFrame: CFrame): LockedCameraZone
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

