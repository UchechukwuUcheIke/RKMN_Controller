--!strict

export type CollisionTolerances = {
    GroundCheckDistance: number,
    WallCheckDistance: number,
    SkinWidth: number,
    MaxSlopeAngle: number,
}

local CollisionTolerances: CollisionTolerances = {
    GroundCheckDistance = 0.05,
    WallCheckDistance = 0.05,
    SkinWidth = 0.1,
    MaxSlopeAngle = 90,
}

return table.freeze(CollisionTolerances)
