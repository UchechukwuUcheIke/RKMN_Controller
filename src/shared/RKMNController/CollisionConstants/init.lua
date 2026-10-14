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
    _characterModel: Model,
    _rootPart: BasePart,
    _hitboxOffset: CFrame,
    _footOffset: CFrame,
}

export type CollisionConstants = typeof(setmetatable({} :: CollisionConstantsData, CollisionConstants))


function CollisionConstants.new(characterModel: Model): CollisionConstants
    assert(characterModel)

    local self = setmetatable({}, CollisionConstants)

    local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart
    assert(rootPart, "CollisionConstants requires a HumanoidRootPart")

    local hitboxCFrame: CFrame, hitboxSize: Vector3 = characterModel:GetBoundingBox()
    local footHeight = 0.1
    local footCFrame = hitboxCFrame - Vector3.new(0, (hitboxSize.Y - footHeight) / 2, 0)
    local footSize = Vector3.new(hitboxSize.X, footHeight, hitboxSize.Z)

    self._characterModel = characterModel
    self._rootPart = rootPart
    self._hitboxOffset = rootPart.CFrame:ToObjectSpace(hitboxCFrame)
    self._footOffset = self._hitboxOffset * CFrame.new(0, -(hitboxSize.Y - footHeight) / 2, 0)
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

-- Boxes are derived from the root part, not the live bounding box, which changes with animation pose.
function CollisionConstants.GetHitboxCFrame(self: CollisionConstants): CFrame
    return self._rootPart.CFrame * self._hitboxOffset
end

-- The hitbox rotates with the character's facing, so its reach along a world direction depends on orientation.
function CollisionConstants.GetHalfExtentAlong(self: CollisionConstants, direction: Vector3): number
    local localDirection = self:GetHitboxCFrame():VectorToObjectSpace(direction)
    local halfSize = self.HitboxSize / 2
    return math.abs(localDirection.X) * halfSize.X
        + math.abs(localDirection.Y) * halfSize.Y
        + math.abs(localDirection.Z) * halfSize.Z
end

function CollisionConstants.GetFootCFrame(self: CollisionConstants): CFrame
    return self._rootPart.CFrame * self._footOffset
end

return CollisionConstants