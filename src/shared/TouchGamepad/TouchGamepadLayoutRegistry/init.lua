--!strict
local InputAction = require(game:GetService("ReplicatedStorage").PlayerInput.InputAction)
local ButtonTransform = require(script.Parent.ButtonTransform)
local TouchLayout = require(script.Parent.TouchLayout)

export type ControlID = TouchLayout.ControlID

export type ButtonTransform = ButtonTransform.ButtonTransform

export type TouchGamepadLayout = TouchLayout.TouchLayout

local TouchGamepadLayoutRegistry = {}

local CENTERED = Vector2.new(0.5, 0.5)
local DEFAULT_SCALE = 1
local DEFAULT_TRANSPARENCY = 0.5

TouchGamepadLayoutRegistry.DPad = "DPad" :: ControlID

TouchGamepadLayoutRegistry.Standard = TouchLayout.new({
    [TouchGamepadLayoutRegistry.DPad] = ButtonTransform.new({
        Position = UDim2.new(0, 145, 1, -90),
        BaseSize = UDim2.new(0, 190, 0, 80),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    }),
    [InputAction.Jump] = ButtonTransform.new({
        Position = UDim2.new(1, -120, 1, -120),
        BaseSize = UDim2.new(0, 80, 0, 80),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    }),
    [InputAction.Dash] = ButtonTransform.new({
        Position = UDim2.new(1, -220, 1, -90),
        BaseSize = UDim2.new(0, 70, 0, 70),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    }),
    [InputAction.Shoot] = ButtonTransform.new({
        Position = UDim2.new(1, -210, 1, -190),
        BaseSize = UDim2.new(0, 70, 0, 70),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    }),
    [InputAction.Menu] = ButtonTransform.new({
        Position = UDim2.new(1, -50, 0, 50),
        BaseSize = UDim2.new(0, 70, 0, 40),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    }),
})

table.freeze(TouchGamepadLayoutRegistry)

return TouchGamepadLayoutRegistry
