--!strict
local TouchGamepadLayoutRegistry = require(script.Parent.TouchGamepadLayoutRegistry)

type ButtonTransform = TouchGamepadLayoutRegistry.ButtonTransform

local ButtonTransformRules = {}

ButtonTransformRules.MIN_SCALE = 0.5
ButtonTransformRules.MAX_SCALE = 1.5
ButtonTransformRules.MIN_TRANSPARENCY = 0
ButtonTransformRules.MAX_TRANSPARENCY = 0.8
-- The player sees opacity, the reverse of Roblox's transparency.
ButtonTransformRules.MIN_OPACITY = 1 - ButtonTransformRules.MAX_TRANSPARENCY
ButtonTransformRules.MAX_OPACITY = 1 - ButtonTransformRules.MIN_TRANSPARENCY

function ButtonTransformRules.TransparencyToOpacity(transparency: number): number
    return 1 - transparency
end

function ButtonTransformRules.OpacityToTransparency(opacity: number): number
    return 1 - opacity
end

function ButtonTransformRules.ClampScale(scale: number): number
    return math.clamp(scale, ButtonTransformRules.MIN_SCALE, ButtonTransformRules.MAX_SCALE)
end

function ButtonTransformRules.ClampTransparency(transparency: number): number
    return math.clamp(transparency, ButtonTransformRules.MIN_TRANSPARENCY, ButtonTransformRules.MAX_TRANSPARENCY)
end

function ButtonTransformRules.GetEffectiveSize(transform: ButtonTransform): UDim2
    local scale = transform.Scale
    local size = transform.BaseSize
    return UDim2.new(size.X.Scale * scale, size.X.Offset * scale, size.Y.Scale * scale, size.Y.Offset * scale)
end

function ButtonTransformRules.GetEffectivePixelSize(transform: ButtonTransform, viewportSize: Vector2): Vector2
    local size = ButtonTransformRules.GetEffectiveSize(transform)
    return Vector2.new(
        size.X.Scale * viewportSize.X + size.X.Offset,
        size.Y.Scale * viewportSize.Y + size.Y.Offset
    )
end

local function clampAxis(position: number, size: number, anchor: number, viewport: number): number
    local lowest = anchor * size / viewport
    local highest = 1 - (1 - anchor) * size / viewport

    if lowest > highest then
        return (lowest + highest) / 2
    end
    return math.clamp(position, lowest, highest)
end

function ButtonTransformRules.ClampPosition(positionScale: Vector2, sizePixels: Vector2, anchorPoint: Vector2, viewportSize: Vector2): Vector2
    if viewportSize.X <= 0 or viewportSize.Y <= 0 then
        return positionScale
    end

    return Vector2.new(
        clampAxis(positionScale.X, sizePixels.X, anchorPoint.X, viewportSize.X),
        clampAxis(positionScale.Y, sizePixels.Y, anchorPoint.Y, viewportSize.Y)
    )
end

table.freeze(ButtonTransformRules)
return ButtonTransformRules
