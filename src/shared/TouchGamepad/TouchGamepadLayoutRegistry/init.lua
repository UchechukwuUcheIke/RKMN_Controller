--!strict
local InputAction = require(game:GetService("ReplicatedStorage").PlayerInput.InputAction)

export type ButtonTransform = {
    Position: UDim2,
    Size: UDim2,
    AnchorPoint: Vector2
}

-- Every action needs a transform; MobileButtonPositioner errors on a missing one.
export type TouchGamepadLayout = {[InputAction.ActionID]: ButtonTransform}

local TouchGamepadLayoutRegistry = {}

local CENTERED = Vector2.new(0.5, 0.5)

local function freezeLayout(layout: TouchGamepadLayout): TouchGamepadLayout
    for _, transform in pairs(layout) do
        table.freeze(transform)
    end
    return table.freeze(layout)
end

-- Default "Two Thumb" layout: movement on the left, actions on the right
TouchGamepadLayoutRegistry.Standard = freezeLayout({
    [InputAction.Left] = {
        Position = UDim2.new(0, 90, 1, -90),
        Size = UDim2.new(0, 80, 0, 80),
        AnchorPoint = CENTERED
    },
    [InputAction.Right] = {
        Position = UDim2.new(0, 200, 1, -90),
        Size = UDim2.new(0, 80, 0, 80),
        AnchorPoint = CENTERED
    },
    [InputAction.Jump] = {
        Position = UDim2.new(1, -120, 1, -120),
        Size = UDim2.new(0, 80, 0, 80),
        AnchorPoint = CENTERED
    },
    [InputAction.Dash] = {
        Position = UDim2.new(1, -220, 1, -90),
        Size = UDim2.new(0, 70, 0, 70),
        AnchorPoint = CENTERED
    },
    [InputAction.Shoot] = {
        Position = UDim2.new(1, -210, 1, -190),
        Size = UDim2.new(0, 70, 0, 70),
        AnchorPoint = CENTERED
    },
})

table.freeze(TouchGamepadLayoutRegistry)

return TouchGamepadLayoutRegistry
