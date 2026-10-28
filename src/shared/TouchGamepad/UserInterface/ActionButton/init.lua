--!strict
local ActionButton = {}
ActionButton.__index = ActionButton

local TouchGamepadLayoutRegistry = require(script.Parent.Parent.TouchGamepadLayoutRegistry)
type ButtonTransform = TouchGamepadLayoutRegistry.ButtonTransform

local RESTING_TRANSPARENCY = 0.5
local PRESSED_TRANSPARENCY = 0.2

type ActionButtonData = {
    _button: TextButton,
    _connections: {RBXScriptConnection}
}

export type ActionButton = typeof(setmetatable({} :: ActionButtonData, ActionButton))

local function isPointerPress(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

function ActionButton.new(name: string, label: string, parent: Instance?): ActionButton
    local self = setmetatable({}, ActionButton)

    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = label
    button.BackgroundTransparency = RESTING_TRANSPARENCY
    button.AutoButtonColor = false
    button.Parent = parent

    self._button = button
    self._connections = {}

    self:_bindVisualFeedback()

    return self :: ActionButton
end

function ActionButton._bindVisualFeedback(self: ActionButton): ()
    table.insert(self._connections, self._button.InputBegan:Connect(function(input)
        if isPointerPress(input) then
            self._button.BackgroundTransparency = PRESSED_TRANSPARENCY
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
    self._button.Size = transform.Size
    self._button.AnchorPoint = transform.AnchorPoint
end

function ActionButton.SetParent(self: ActionButton, parent: Instance?): ()
    self._button.Parent = parent
end

function ActionButton.ResetVisual(self: ActionButton): ()
    self._button.BackgroundTransparency = RESTING_TRANSPARENCY
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
