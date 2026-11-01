--!strict
local Panel = {}
Panel.__index = Panel

local UITheme = require(script.Parent.UITheme)

export type PanelTone = "Window" | "Row" | "RowHighlighted"

export type PanelProps = {
    Name: string?,
    Tone: PanelTone?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    Visible: boolean?
}

type PanelData = {
    _frame: Frame
}

export type Panel = typeof(setmetatable({} :: PanelData, Panel))

local TONE_COLORS: {[PanelTone]: Color3} = {
    Window = UITheme.Colors.Window,
    Row = UITheme.Colors.Row,
    RowHighlighted = UITheme.Colors.RowHighlighted,
}

local CORNER_RADII: {[PanelTone]: UDim} = {
    Window = UITheme.WindowCornerRadius,
    Row = UITheme.RowCornerRadius,
    RowHighlighted = UITheme.RowCornerRadius,
}

local function createFrame(props: PanelProps, tone: PanelTone): Frame
    local frame = Instance.new("Frame")
    frame.Name = props.Name or "Panel"
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = TONE_COLORS[tone]
    frame.Size = props.Size or UDim2.fromScale(1, 1)
    frame.Position = props.Position or UDim2.new()
    frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    frame.LayoutOrder = props.LayoutOrder or 0
    frame.Visible = props.Visible ~= false
    return frame
end

local function addRoundedCorners(parent: GuiObject, tone: PanelTone): ()
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CORNER_RADII[tone]
    corner.Parent = parent
end

function Panel.new(props: PanelProps): Panel
    local tone = props.Tone or "Window"
    local frame = createFrame(props, tone)
    addRoundedCorners(frame, tone)

    local self = setmetatable({}, Panel)
    self._frame = frame
    return self :: Panel
end

function Panel.GetGuiObject(self: Panel): GuiObject
    return self._frame
end

function Panel.SetTone(self: Panel, tone: PanelTone): ()
    self._frame.BackgroundColor3 = TONE_COLORS[tone]
end

function Panel.SetVisible(self: Panel, isVisible: boolean): ()
    self._frame.Visible = isVisible
end

function Panel.Destroy(self: Panel): ()
    self._frame:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(Panel)
return Panel
