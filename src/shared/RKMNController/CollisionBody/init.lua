--!strict

local CollisionBody = {}
CollisionBody.__index = CollisionBody

local FOOT_HEIGHT = 0.1

type CollisionBodyData = {
    BodySize: Vector3,
    BodyCFrame: CFrame,
    FootCFrame: CFrame,
    FootSize: Vector3,
    HalfWidth: number,
    _characterModel: Model,
    _rootPart: BasePart,
    _bodyOffset: CFrame,
    _footOffset: CFrame,
}

export type CollisionBody = typeof(setmetatable({} :: CollisionBodyData, CollisionBody))

function CollisionBody.new(characterModel: Model): CollisionBody
    assert(characterModel)

    local self = setmetatable({}, CollisionBody)

    local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart
    assert(rootPart, "CollisionBody requires a HumanoidRootPart")

    local bodyCFrame: CFrame, bodySize: Vector3 = characterModel:GetBoundingBox()
    local footCFrame = bodyCFrame - Vector3.new(0, (bodySize.Y - FOOT_HEIGHT) / 2, 0)
    local footSize = Vector3.new(bodySize.X, FOOT_HEIGHT, bodySize.Z)

    self._characterModel = characterModel
    self._rootPart = rootPart
    self._bodyOffset = rootPart.CFrame:ToObjectSpace(bodyCFrame)
    self._footOffset = self._bodyOffset * CFrame.new(0, -(bodySize.Y - FOOT_HEIGHT) / 2, 0)
    self.BodySize = bodySize
    self.BodyCFrame = bodyCFrame
    self.FootCFrame = footCFrame
    self.FootSize = footSize
    self.HalfWidth = bodySize.X / 2

    return self
end

-- Boxes are derived from the root part, not the live bounding box, which changes with animation pose.
function CollisionBody.GetBodyCFrame(self: CollisionBody): CFrame
    return self._rootPart.CFrame * self._bodyOffset
end

-- The body rotates with the character's facing, so its reach along a world direction depends on orientation.
function CollisionBody.GetHalfExtentAlong(self: CollisionBody, direction: Vector3): number
    local localDirection = self:GetBodyCFrame():VectorToObjectSpace(direction)
    local halfSize = self.BodySize / 2
    return math.abs(localDirection.X) * halfSize.X
        + math.abs(localDirection.Y) * halfSize.Y
        + math.abs(localDirection.Z) * halfSize.Z
end

function CollisionBody.GetFootCFrame(self: CollisionBody): CFrame
    return self._rootPart.CFrame * self._footOffset
end

return CollisionBody
