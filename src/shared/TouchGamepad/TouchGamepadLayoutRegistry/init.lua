--!strict
local InputAction = require(game:GetService("ReplicatedStorage").PlayerInput.InputAction)

export type ControlID = "DPad" | InputAction.ActionID

export type ButtonTransform = {
    Position: UDim2,
    BaseSize: UDim2,
    AnchorPoint: Vector2,
    Scale: number,
    Transparency: number
}

export type TouchGamepadLayout = {[ControlID]: ButtonTransform}

local TouchGamepadLayoutRegistry = {}

local CENTERED = Vector2.new(0.5, 0.5)
local DEFAULT_SCALE = 1
local DEFAULT_TRANSPARENCY = 0.5

TouchGamepadLayoutRegistry.DPad = "DPad" :: ControlID

local function freezeLayout(layout: TouchGamepadLayout): TouchGamepadLayout
    for _, transform in pairs(layout) do
        table.freeze(transform)
    end
    return table.freeze(layout)
end

TouchGamepadLayoutRegistry.Standard = freezeLayout({
    [TouchGamepadLayoutRegistry.DPad] = {
        Position = UDim2.new(0, 145, 1, -90),
        BaseSize = UDim2.new(0, 190, 0, 80),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    },
    [InputAction.Jump] = {
        Position = UDim2.new(1, -120, 1, -120),
        BaseSize = UDim2.new(0, 80, 0, 80),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    },
    [InputAction.Dash] = {
        Position = UDim2.new(1, -220, 1, -90),
        BaseSize = UDim2.new(0, 70, 0, 70),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    },
    [InputAction.Shoot] = {
        Position = UDim2.new(1, -210, 1, -190),
        BaseSize = UDim2.new(0, 70, 0, 70),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    },
    [InputAction.Menu] = {
        Position = UDim2.new(1, -50, 0, 50),
        BaseSize = UDim2.new(0, 70, 0, 40),
        AnchorPoint = CENTERED,
        Scale = DEFAULT_SCALE,
        Transparency = DEFAULT_TRANSPARENCY
    },
})

table.freeze(TouchGamepadLayoutRegistry)

return TouchGamepadLayoutRegistry
