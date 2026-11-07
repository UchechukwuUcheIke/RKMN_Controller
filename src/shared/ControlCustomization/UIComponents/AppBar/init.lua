--!strict
local AppBar = {}
AppBar.__index = AppBar

local UIComponents = script.Parent
local Label = require(UIComponents.Label)
local Panel = require(UIComponents.Panel)
local PanelTone = require(UIComponents.PanelTone)

type Label = Label.Label
type Panel = Panel.Panel

export type AppBarProps = {
    Name: string?,
    Title: string?,
    Size: UDim2?,
    LayoutOrder: number?
}

type AppBarData = {
    _panel: Panel,
    _titleLabel: Label,
    _actionsContainer: Frame
}

export type AppBar = typeof(setmetatable({} :: AppBarData, AppBar))

local DEFAULT_SIZE = UDim2.new(1, 0, 0, 44)
local TITLE_INSET = 12
local ACTIONS_INSET = 8
local ACTION_SPACING = 6

local function createPanel(props: AppBarProps): Panel
    local panelProps: Panel.PanelProps = {
        Name = props.Name or "AppBar",
        Tone = PanelTone.AppBar,
        Size = props.Size or DEFAULT_SIZE,
        LayoutOrder = props.LayoutOrder,
    }
    return Panel.new(panelProps)
end

local function createTitleLabel(title: string?): Label
    local labelProps: Label.LabelProps = {
        Name = "Title",
        Text = title,
        Position = UDim2.fromOffset(TITLE_INSET, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
    }
    return Label.new(labelProps)
end

local function createActionsContainer(): Frame
    local container = Instance.new("Frame")
    container.Name = "Actions"
    container.BackgroundTransparency = 1
    container.AnchorPoint = Vector2.new(1, 0.5)
    container.Position = UDim2.new(1, -ACTIONS_INSET, 0.5, 0)
    container.Size = UDim2.fromScale(0, 1)
    container.AutomaticSize = Enum.AutomaticSize.X

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, ACTION_SPACING)
    layout.Parent = container

    return container
end

function AppBar.new(props: AppBarProps): AppBar
    local self = setmetatable({}, AppBar)

    self._panel = createPanel(props)
    self._titleLabel = createTitleLabel(props.Title)
    self._actionsContainer = createActionsContainer()

    local panelObject = self._panel:GetGuiObject()
    self._titleLabel:GetGuiObject().Parent = panelObject
    self._actionsContainer.Parent = panelObject

    return self :: AppBar
end

function AppBar.GetGuiObject(self: AppBar): GuiObject
    return self._panel:GetGuiObject()
end

function AppBar.SetTitle(self: AppBar, title: string): ()
    self._titleLabel:SetText(title)
end

-- Actions sit at the right end, in the order they were added.
function AppBar.AddAction(self: AppBar, action: GuiObject): ()
    action.LayoutOrder = #self._actionsContainer:GetChildren()
    action.Parent = self._actionsContainer
end

function AppBar.Destroy(self: AppBar): ()
    self._titleLabel:Destroy()
    self._actionsContainer:Destroy()
    self._panel:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(AppBar)
return AppBar
