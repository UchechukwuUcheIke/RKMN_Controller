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
    _characterModel: Model
}

export type CollisionConstants = typeof(setmetatable({} :: CollisionConstantsData, CollisionConstants))


function CollisionConstants.new(characterModel: Model): CollisionConstants
    assert(characterModel)

    local self = setmetatable({}, CollisionConstants)

    local hitboxCFrame: CFrame, hitboxSize: Vector3 = characterModel:GetBoundingBox()
    local footHeight = 0.1
    local footCFrame = hitboxCFrame - Vector3.new(0, (hitboxSize.Y - footHeight) / 2, 0)
    local footSize = Vector3.new(hitboxSize.X, footHeight, hitboxSize.Z)

    self._characterModel = characterModel
    self.HitboxSize = hitboxSize
    self.HitboxCFrame = hitboxCFrame
    self.FootCFrame = footCFrame
    self.FootSize = footSize
    self.HalfWidth = hitboxSize.X/2
    self.GroundCheckDistance = 0.05
    self.WallCheckDistance = 0.05
    self.MaxSlopeAngle = 90
    self.SkinWidth = 0.1

    return self
end

function CollisionConstants.GetHitboxCFrame(self: CollisionConstants): CFrame
    local hitboxCFrame: CFrame, _: Vector3 = self._characterModel:GetBoundingBox()
    return hitboxCFrame
end

function CollisionConstants.GetFootCFrame(self: CollisionConstants): CFrame
    local hitboxCFrame: CFrame, hitboxSize: Vector3 = self._characterModel:GetBoundingBox()
    local footCFrame = hitboxCFrame - Vector3.new(0, (hitboxSize.Y - self.FootSize.Y) / 2, 0)
    return footCFrame
end

return CollisionConstants