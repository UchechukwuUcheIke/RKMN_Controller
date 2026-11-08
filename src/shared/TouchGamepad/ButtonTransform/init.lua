--!strict
local ButtonTransform = {}
ButtonTransform.__index = ButtonTransform

export type ButtonTransformProps = {
    Position: UDim2,
    BaseSize: UDim2,
    AnchorPoint: Vector2,
    Scale: number,
    Transparency: number
}

export type ButtonTransformChanges = {
    Position: UDim2?,
    BaseSize: UDim2?,
    AnchorPoint: Vector2?,
    Scale: number?,
    Transparency: number?
}

type ButtonTransformData = ButtonTransformProps

export type ButtonTransform = typeof(setmetatable({} :: ButtonTransformData, ButtonTransform))

function ButtonTransform.new(props: ButtonTransformProps): ButtonTransform
    local self = setmetatable({}, ButtonTransform)

    self.Position = props.Position
    self.BaseSize = props.BaseSize
    self.AnchorPoint = props.AnchorPoint
    self.Scale = props.Scale
    self.Transparency = props.Transparency

    return table.freeze(self) :: ButtonTransform
end

function ButtonTransform.CopyWithChanges(self: ButtonTransform, changes: ButtonTransformChanges): ButtonTransform
    return ButtonTransform.new({
        Position = changes.Position or self.Position,
        BaseSize = changes.BaseSize or self.BaseSize,
        AnchorPoint = changes.AnchorPoint or self.AnchorPoint,
        Scale = changes.Scale or self.Scale,
        Transparency = changes.Transparency or self.Transparency
    })
end

function ButtonTransform.Equals(self: ButtonTransform, other: ButtonTransform): boolean
    return self.Position == other.Position
        and self.BaseSize == other.BaseSize
        and self.AnchorPoint == other.AnchorPoint
        and self.Scale == other.Scale
        and self.Transparency == other.Transparency
end

table.freeze(ButtonTransform)
return ButtonTransform
