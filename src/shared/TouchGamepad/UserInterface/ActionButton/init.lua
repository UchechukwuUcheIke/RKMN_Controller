--!strict
local ActionButton = {}
ActionButton.__index = ActionButton

local TouchGamepadLayoutRegistry = require(script.Parent.Parent.TouchGamepadLayoutRegistry)
local ButtonTransformRules = require(script.Parent.Parent.ButtonTransformRules)
type ButtonTransform = TouchGamepadLayoutRegistry.ButtonTransform

local DEFAULT_RESTING_TRANSPARENCY = 0.5
-- A press makes the button this much more solid than its resting look, whatever the player set that to.
local PRESSED_TRANSPARENCY_DROP = 0.3

export type ButtonShape = "Circle" | "Rounded"

local CORNER_RADII: {[ButtonShape]: UDim} = {
    Circle = UDim.new(0.5, 0),
    Rounded = UDim.new(0, 12),
}

type ActionButtonData = {
    _button: TextButton,
    _restingTransparency: number,
    _connections: {RBXScriptConnection}
}

export type ActionButton = typeof(setmetatable({} :: ActionButtonData, ActionButton))

local function isPointerPress(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

function ActionButton.new(name: string, label: string, parent: Instance?, shape: ButtonShape?): ActionButton
    local self = setmetatable({}, ActionButton)

    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = label
    button.BackgroundTransparency = DEFAULT_RESTING_TRANSPARENCY
    button.AutoButtonColor = false

    local corner = Instance.new("UICorner")
    corner.CornerRadius = CORNER_RADII[shape or "Rounded"]
    corner.Parent = button

    button.Parent = parent

    self._button = button
    self._restingTransparency = DEFAULT_RESTING_TRANSPARENCY
    self._connections = {}

    self:_bindVisualFeedback()

    return self :: ActionButton
end

function ActionButton._bindVisualFeedback(self: ActionButton): ()
    table.insert(self._connections, self._button.InputBegan:Connect(function(input)
        if isPointerPress(input) then
            self._button.BackgroundTransparency = math.max(0, self._restingTransparency - PRESSED_TRANSPARENCY_DROP)
        end
    end))

    table.insert(self._connections, self._button.InputEnded:Connect(function(input)
        if isPointerPress(input) then
            self:ResetVisual()
        end
    end))

    table.insert(self._connections, self._button.MouseLeave:Connect(function()
        self:ResetVisual()
    end))
end

function ActionButton.SetTransform(self: ActionButton, transform: ButtonTransform): ()
    self._button.Position = transform.Position
    self._button.Size = ButtonTransformRules.GetEffectiveSize(transform)
    self._button.AnchorPoint = transform.AnchorPoint
    self._restingTransparency = transform.Transparency
    self:ResetVisual()
end

function ActionButton.SetParent(self: ActionButton, parent: Instance?): ()
    self._button.Parent = parent
end

function ActionButton.ResetVisual(self: ActionButton): ()
    self._button.BackgroundTransparency = self._restingTransparency
end

function ActionButton.GetInstance(self: ActionButton): GuiButton
    return self._button
end

function ActionButton.Destroy(self: ActionButton): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    self._button:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ActionButton)
return ActionButton
