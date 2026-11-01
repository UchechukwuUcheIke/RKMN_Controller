--!strict
local Button = {}
Button.__index = Button

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local UITheme = require(script.Parent.UITheme)

type Signal = typeof(Signal)

export type ButtonProps = {
    Name: string?,
    Text: string?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    Enabled: boolean?
}

type ButtonData = {
    _textButton: TextButton,
    _border: UIStroke,
    _invisibleSelectionImage: Frame,
    _connections: {RBXScriptConnection},
    _isEnabled: boolean,
    _isHovered: boolean,
    _isPressed: boolean,
    _isFocused: boolean,
    Activated: Signal
}

export type Button = typeof(setmetatable({} :: ButtonData, Button))

local DEFAULT_SIZE = UDim2.fromOffset(120, 40)

local function createTextButton(props: ButtonProps): TextButton
    local textButton = Instance.new("TextButton")
    textButton.Name = props.Name or "Button"
    textButton.Size = props.Size or DEFAULT_SIZE
    textButton.Position = props.Position or UDim2.new()
    textButton.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    textButton.LayoutOrder = props.LayoutOrder or 0
    textButton.Text = props.Text or ""
    textButton.TextSize = UITheme.TextSizes.Button
    textButton.Font = UITheme.Fonts.Body
    textButton.BorderSizePixel = 0
    textButton.AutoButtonColor = false
    return textButton
end

local function addRoundedCorners(parent: GuiObject): ()
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UITheme.ButtonCornerRadius
    corner.Parent = parent
end

local function addBorder(parent: GuiObject): UIStroke
    local border = Instance.new("UIStroke")
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = parent
    return border
end

local function createInvisibleSelectionImage(): Frame
    local image = Instance.new("Frame")
    image.BackgroundTransparency = 1
    image.BorderSizePixel = 0
    return image
end

function Button.new(props: ButtonProps): Button
    local textButton = createTextButton(props)
    local invisibleSelectionImage = createInvisibleSelectionImage()
    textButton.SelectionImageObject = invisibleSelectionImage
    addRoundedCorners(textButton)

    local self = setmetatable({}, Button)

    self._textButton = textButton
    self._border = addBorder(textButton)
    self._invisibleSelectionImage = invisibleSelectionImage
    self._connections = {}
    self._isEnabled = props.Enabled ~= false
    self._isHovered = false
    self._isPressed = false
    self._isFocused = false
    self.Activated = Signal.new()

    textButton.Selectable = self._isEnabled

    self:_subscribeToGuiEvents()
    self:_renderCurrentState()

    return self :: Button
end

function Button.GetGuiObject(self: Button): GuiObject
    return self._textButton
end

function Button.SetText(self: Button, text: string): ()
    self._textButton.Text = text
end

function Button.Enable(self: Button): ()
    self._isEnabled = true
    self._textButton.Selectable = true
    self:_renderCurrentState()
end

function Button.Disable(self: Button): ()
    self._isEnabled = false
    self._textButton.Selectable = false
    self:_clearHoverAndPress()
    self:_renderCurrentState()
end

function Button.IsEnabled(self: Button): boolean
    return self._isEnabled
end

function Button._subscribeToGuiEvents(self: Button): ()
    local textButton = self._textButton

    self:_addConnection(textButton.Activated, function() self:_handleActivated() end)
    self:_addConnection(textButton.MouseEnter, function() self:_handleMouseEntered() end)
    self:_addConnection(textButton.MouseLeave, function() self:_handleMouseLeft() end)
    self:_addConnection(textButton.MouseButton1Down, function() self:_handlePressStarted() end)
    self:_addConnection(textButton.MouseButton1Up, function() self:_handlePressEnded() end)
    self:_addConnection(textButton.SelectionGained, function() self:_handleFocusGained() end)
    self:_addConnection(textButton.SelectionLost, function() self:_handleFocusLost() end)
end

function Button._addConnection(self: Button, signal: RBXScriptSignal, handler: () -> ()): ()
    local connection = signal:Connect(handler)
    table.insert(self._connections, connection)
end

function Button._handleActivated(self: Button): ()
    if self._isEnabled then
        self.Activated:Fire()
    end
end

function Button._handleMouseEntered(self: Button): ()
    self._isHovered = true
    self:_renderCurrentState()
end

function Button._handleMouseLeft(self: Button): ()
    self:_clearHoverAndPress()
    self:_renderCurrentState()
end

function Button._handlePressStarted(self: Button): ()
    self._isPressed = true
    self:_renderCurrentState()
end

function Button._handlePressEnded(self: Button): ()
    self._isPressed = false
    self:_renderCurrentState()
end

function Button._handleFocusGained(self: Button): ()
    self._isFocused = true
    self:_renderCurrentState()
end

function Button._handleFocusLost(self: Button): ()
    self._isFocused = false
    self:_renderCurrentState()
end

function Button._clearHoverAndPress(self: Button): ()
    self._isHovered = false
    self._isPressed = false
end

function Button._renderCurrentState(self: Button): ()
    self:_renderBackground()
    self:_renderText()
    self:_renderBorder()
end

function Button._renderBackground(self: Button): ()
    self._textButton.BackgroundColor3 = self:_chooseBackgroundColor()
end

function Button._renderText(self: Button): ()
    self._textButton.TextColor3 = if self._isEnabled then UITheme.Colors.Text else UITheme.Colors.DisabledText
end

function Button._renderBorder(self: Button): ()
    if self:_shouldShowFocusRing() then
        self._border.Color = UITheme.Colors.FocusRing
        self._border.Thickness = UITheme.FocusRingThickness
    else
        self._border.Color = UITheme.Colors.ButtonBorder
        self._border.Thickness = UITheme.ButtonBorderThickness
    end
end

function Button._chooseBackgroundColor(self: Button): Color3
    if not self._isEnabled then
        return UITheme.Colors.ButtonDisabled
    end
    if self._isPressed then
        return UITheme.Colors.ButtonPressed
    end
    if self._isHovered then
        return UITheme.Colors.ButtonHovered
    end
    return UITheme.Colors.ButtonNormal
end

function Button._shouldShowFocusRing(self: Button): boolean
    return self._isFocused and self._isEnabled
end

function Button._destroyConnections(self: Button): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function Button.Destroy(self: Button): ()
    self:_destroyConnections()
    self.Activated:DisconnectAll()
    self._invisibleSelectionImage:Destroy()
    self._textButton:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(Button)
return Button
