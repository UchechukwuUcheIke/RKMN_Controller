--!strict
local TextInput = {}
TextInput.__index = TextInput

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local UITheme = require(script.Parent.UITheme)

type Signal = typeof(Signal)

export type TextInputProps = {
    Name: string?,
    Text: string?,
    PlaceholderText: string?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    MaxLength: number?,
    MultiLine: boolean?,
    Enabled: boolean?
}

type TextInputData = {
    _textBox: TextBox,
    _border: UIStroke,
    _connections: {RBXScriptConnection},
    _isEnabled: boolean,
    _isFocused: boolean,
    TextChanged: Signal
    textBox.MaxGraphemes
}

export type TextInput = typeof(setmetatable({} :: TextInputData, TextInput))

local DEFAULT_SIZE = UDim2.new(1, 0, 0, 120)
local NO_LENGTH_LIMIT = -1

local function createTextBox(props: TextInputProps): TextBox
    local isMultiLine = props.MultiLine ~= false

    local textBox = Instance.new("TextBox")
    textBox.Name = props.Name or "TextInput"
    textBox.Size = props.Size or DEFAULT_SIZE
    textBox.Position = props.Position or UDim2.new()
    textBox.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    textBox.LayoutOrder = props.LayoutOrder or 0
    textBox.Text = props.Text or ""
    textBox.PlaceholderText = props.PlaceholderText or ""
    textBox.PlaceholderColor3 = UITheme.Colors.PlaceholderText
    textBox.MaxVisibleGraphemes = props.MaxLength or NO_LENGTH_LIMIT
    textBox.Font = UITheme.Fonts.Body
    textBox.TextSize = UITheme.TextSizes.Body
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = if isMultiLine then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center
    textBox.MultiLine = isMultiLine
    textBox.TextWrapped = isMultiLine
    textBox.ClearTextOnFocus = false
    textBox.BorderSizePixel = 0
    return textBox
end

local function addPadding(parent: GuiObject): ()
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, UITheme.InputPadding)
    padding.PaddingRight = UDim.new(0, UITheme.InputPadding)
    padding.PaddingTop = UDim.new(0, UITheme.InputPadding)
    padding.PaddingBottom = UDim.new(0, UITheme.InputPadding)
    padding.Parent = parent
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

function TextInput.new(props: TextInputProps): TextInput
    local textBox = createTextBox(props)
    addPadding(textBox)
    addRoundedCorners(textBox)

    local self = setmetatable({}, TextInput)

    self._textBox = textBox
    self._border = addBorder(textBox)
    self._connections = {}
    self._isEnabled = props.Enabled ~= false
    self._isFocused = false
    self.TextChanged = Signal.new()

    self:_subscribeToGuiEvents()
    self:_renderCurrentState()

    return self :: TextInput
end

function TextInput.GetGuiObject(self: TextInput): GuiObject
    return self._textBox
end

function TextInput.GetText(self: TextInput): string
    return self._textBox.Text
end

function TextInput.SetText(self: TextInput, text: string): ()
    self._textBox.Text = text
end

function TextInput.Enable(self: TextInput): ()
    self._isEnabled = true
    self:_renderCurrentState()
end

function TextInput.Disable(self: TextInput): ()
    self._isEnabled = false
    self._isFocused = false
    self._textBox:ReleaseFocus()
    self:_renderCurrentState()
end

function TextInput.IsEnabled(self: TextInput): boolean
    return self._isEnabled
end

function TextInput.CaptureFocus(self: TextInput): ()
    if self._isEnabled then
        self._textBox:CaptureFocus()
    end
end

function TextInput._subscribeToGuiEvents(self: TextInput): ()
    local textBox = self._textBox

    self:_addConnection(textBox:GetPropertyChangedSignal("Text"), function() self:_handleTextChanged() end)
    self:_addConnection(textBox.Focused, function() self:_handleFocusGained() end)
    self:_addConnection(textBox.FocusLost, function() self:_handleFocusLost() end)
end

function TextInput._addConnection(self: TextInput, signal: RBXScriptSignal, handler: () -> ()): ()
    local connection = signal:Connect(handler)
    table.insert(self._connections, connection)
end

function TextInput._handleTextChanged(self: TextInput): ()
    self.TextChanged:Fire(self._textBox.Text)
end

function TextInput._handleFocusGained(self: TextInput): ()
    if not self._isEnabled then
        self._textBox:ReleaseFocus()
        return
    end

    self._isFocused = true
    self:_renderCurrentState()
end

function TextInput._handleFocusLost(self: TextInput): ()
    self._isFocused = false
    self:_renderCurrentState()
end

function TextInput._renderCurrentState(self: TextInput): ()
    self:_renderEditability()
    self:_renderBackground()
    self:_renderText()
    self:_renderBorder()
end

function TextInput._renderEditability(self: TextInput): ()
    self._textBox.TextEditable = self._isEnabled
end

function TextInput._renderBackground(self: TextInput): ()
    self._textBox.BackgroundColor3 = if self._isEnabled then UITheme.Colors.InputBackground else UITheme.Colors.ButtonDisabled
end

function TextInput._renderText(self: TextInput): ()
    self._textBox.TextColor3 = if self._isEnabled then UITheme.Colors.Text else UITheme.Colors.DisabledText
end

function TextInput._renderBorder(self: TextInput): ()
    if self._isFocused then
        self._border.Color = UITheme.Colors.FocusRing
        self._border.Thickness = UITheme.FocusRingThickness
    else
        self._border.Color = UITheme.Colors.ButtonBorder
        self._border.Thickness = UITheme.ButtonBorderThickness
    end
end

function TextInput._destroyConnections(self: TextInput): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function TextInput.Destroy(self: TextInput): ()
    self:_destroyConnections()
    self.TextChanged:DisconnectAll()
    self._textBox:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TextInput)
return TextInput
