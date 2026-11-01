--!strict
local TouchGamepadLayoutRegistry = require(script.Parent.TouchGamepadLayoutRegistry)

type ButtonTransform = TouchGamepadLayoutRegistry.ButtonTransform

local ButtonTransformRules = {}

ButtonTransformRules.MIN_SCALE = 0.5
ButtonTransformRules.MAX_SCALE = 1.5
ButtonTransformRules.MIN_TRANSPARENCY = 0
ButtonTransformRules.MAX_TRANSPARENCY = 0.8

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

table.freeze(ButtonTransformRules)
return ButtonTransformRules
