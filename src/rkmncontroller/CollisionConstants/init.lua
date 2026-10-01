--!strict

local CollisionConstants = {}
CollisionConstants.__index = CollisionConstants

type CollisionConstantsData = {
	HitboxSize: Vector3,
    HitboxCFrame: CFrame,
    FootCFrame: CFrame,
    FootSize: Vector3,
    HalfWidth: number,
	GroundCheckDistance: number,
	WallCheckDistance: number,
	MaxSlopeAngle: number,
	SkinWidth: number,
}

export type CollisionConstants = typeof(setmetatable({} :: CollisionConstantsData, CollisionConstants))


function CollisionConstants.new(characterModel: Model): CollisionConstants
    assert(characterModel)

    local self = setmetatable({}, CollisionConstants)

    local hitboxCFrame: CFrame, hitboxSize: Vector3 = characterModel:GetBoundingBox()
    local footCFrame = hitboxCFrame - Vector3.new(0, hitboxSize.Y, 0)
    local footSize = Vector3.new(hitboxSize.X, 0.1, hitboxSize.Z)

    self.HitboxSize = hitboxSize
    self.HitboxCFrame = hitboxCFrame
    self.FootCFrame = footCFrame
    self.FootSize = footSize
    self.HalfWidth = hitboxSize.X/2
    self.GroundCheckDistance = 2
    self.WallCheckDistance = 2
    self.MaxSlopeAngle = 90
    self.SkinWidth = 2

    return self
end

return CollisionConstants