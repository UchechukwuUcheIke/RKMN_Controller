--!strict
local Label = {}
Label.__index = Label

local UITheme = require(script.Parent.UITheme)

export type LabelStyle = "Body" | "Title"

export type LabelProps = {
    Name: string?,
    Text: string?,
    Style: LabelStyle?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    Alignment: Enum.TextXAlignment?
}

type LabelData = {
    _textLabel: TextLabel
}

export type Label = typeof(setmetatable({} :: LabelData, Label))

local DEFAULT_SIZE = UDim2.new(1, 0, 0, 28)

local function applyTitleStyling(textLabel: TextLabel)
    textLabel.Font = UITheme.Fonts.Title
    textLabel.TextSize = UITheme.TextSizes.Title
    textLabel.TextColor3 = UITheme.Colors.TitleText
end

local function applyBodyStyling(textLabel: TextLabel)
    textLabel.Font = UITheme.Fonts.Body
    textLabel.TextSize = UITheme.TextSizes.Body
    textLabel.TextColor3 = UITheme.Colors.Text
end

local function applyStylingFromProperties(textLabel: TextLabel, props: LabelProps)
    textLabel.Name = props.Name or "Label"
    textLabel.BackgroundTransparency = 1
    textLabel.BorderSizePixel = 0
    textLabel.Size = props.Size or DEFAULT_SIZE
    textLabel.Position = props.Position or UDim2.new()
    textLabel.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    textLabel.LayoutOrder = props.LayoutOrder or 0
    textLabel.Text = props.Text or ""
    textLabel.TextXAlignment = props.Alignment or Enum.TextXAlignment.Left
end

local function createTextLabel(props: LabelProps): TextLabel
    local style = props.Style or "Body"

    local textLabel = Instance.new("TextLabel")
    applyStylingFromProperties(textLabel, props)

    if style == "Title" then
        applyTitleStyling(textLabel)
    else
        applyBodyStyling(textLabel)
    end

    return textLabel
end

function Label.new(props: LabelProps): Label
    local self = setmetatable({}, Label)
    self._textLabel = createTextLabel(props)
    return self :: Label
end

function Label.GetGuiObject(self: Label): GuiObject
    return self._textLabel
end

function Label.SetText(self: Label, text: string): ()
    self._textLabel.Text = text
end

function Label.Destroy(self: Label): ()
    self._textLabel:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(Label)
return Label
