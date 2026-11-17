--!strict

local CollisionBody = {}
CollisionBody.__index = CollisionBody

local FOOT_HEIGHT = 0.1

type CollisionBodyData = {
    _bodySize: Vector3,
    _footSize: Vector3,
    _halfWidth: number,
    _characterModel: Model,
    _rootPart: BasePart,
    _bodyOffset: CFrame,
    _footOffset: CFrame,
}

export type CollisionBody = typeof(setmetatable({} :: CollisionBodyData, CollisionBody))

local function validateModel(characterModel: Model): ()
    assert(characterModel)
    local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart
    assert(rootPart, "CollisionBody requires a HumanoidRootPart")
end

function CollisionBody.new(characterModel: Model): CollisionBody
    validateModel(characterModel)
    local self = setmetatable({}, CollisionBody)

    local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart

    local bodyCFrame: CFrame, bodySize: Vector3 = characterModel:GetBoundingBox()
    local footSize = Vector3.new(bodySize.X, FOOT_HEIGHT, bodySize.Z)

    self._characterModel = characterModel
    self._rootPart = rootPart
    self._bodyOffset = rootPart.CFrame:ToObjectSpace(bodyCFrame)
    self._footOffset = self._bodyOffset * CFrame.new(0, -(bodySize.Y - FOOT_HEIGHT) / 2, 0)
    self._bodySize = bodySize
    self._footSize = footSize
    self._halfWidth = bodySize.X / 2

    return self
end

function CollisionBody.GetBodySize(self: CollisionBody): Vector3
    return self._bodySize
end

function CollisionBody.GetFootSize(self: CollisionBody): Vector3
    return self._footSize
end

function CollisionBody.GetHalfWidth(self: CollisionBody): number
    return self._halfWidth
end

function CollisionBody.GetBodyCFrame(self: CollisionBody): CFrame
    return self._rootPart.CFrame * self._bodyOffset
end

function CollisionBody.GetHalfExtentAlongDirection(self: CollisionBody, direction: Vector3): number
    local localDirection = self:GetBodyCFrame():VectorToObjectSpace(direction)
    local halfSize = self._bodySize / 2
    return math.abs(localDirection.X) * halfSize.X
        + math.abs(localDirection.Y) * halfSize.Y
        + math.abs(localDirection.Z) * halfSize.Z
end

function CollisionBody.GetFootCFrame(self: CollisionBody): CFrame
    return self._rootPart.CFrame * self._footOffset
end

return CollisionBody
