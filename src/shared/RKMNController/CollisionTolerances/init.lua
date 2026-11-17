--!strict

local CollisionTolerances = {}

export type CollisionTolerances = {
    GroundCheckDistance: number,
    WallCheckDistance: number,
    SkinWidth: number,
    MaxSlopeAngle: number,
}

CollisionTolerances.Default = table.freeze({
    GroundCheckDistance = 0.05,
    WallCheckDistance = 0.05,
    SkinWidth = 0.1,
    MaxSlopeAngle = 90,
} :: CollisionTolerances)

return table.freeze(CollisionTolerances)
