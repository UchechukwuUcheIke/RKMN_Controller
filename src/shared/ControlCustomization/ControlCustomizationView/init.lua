--!strict
local ControlCustomizationView = {}
ControlCustomizationView.__index = ControlCustomizationView

local BindingsScreen = require(script.Parent.BindingsScreen)
local UIComponents = script.Parent.UIComponents
local Label = require(UIComponents.Label)
local Panel = require(UIComponents.Panel)

type BindingsScreen = BindingsScreen.BindingsScreen
type Label = Label.Label
type Panel = Panel.Panel

type ControlCustomizationViewData = {
    _panel: Panel,
    _titleLabel: Label,
    _content: Frame,
    _bindingsScreen: BindingsScreen
}

export type ControlCustomizationView = typeof(setmetatable({} :: ControlCustomizationViewData, ControlCustomizationView))

local TITLE_HEIGHT = 56
local PANEL_PADDING = 16

local function createPanel(): Panel
    local panelProps: Panel.PanelProps = {
        Tone = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(520, 420),
        Visible = false,
    }
    return Panel.new(panelProps)
end

local function createTitleLabel(): Label
    local labelProps: Label.LabelProps = {
        Name = "Title",
        Text = "Controls",
        Style = "Title",
        Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
        Alignment = Enum.TextXAlignment.Center,
    }
    return Label.new(labelProps)
end

local function createContent(): Frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, PANEL_PADDING, 0, TITLE_HEIGHT)
    content.Size = UDim2.new(1, -PANEL_PADDING * 2, 1, -TITLE_HEIGHT - PANEL_PADDING)
    return content
end

function ControlCustomizationView.new(parent: LayerCollector): ControlCustomizationView
    local self = setmetatable({}, ControlCustomizationView)

    self._panel = createPanel()
    self._titleLabel = createTitleLabel()
    self._content = createContent()

    local panelObject = self._panel:GetGuiObject()
    self._titleLabel:GetGuiObject().Parent = panelObject
    self._content.Parent = panelObject
    panelObject.Parent = parent

    self._bindingsScreen = BindingsScreen.new(self._content)

    return self :: ControlCustomizationView
end

function ControlCustomizationView.GetBindingsScreen(self: ControlCustomizationView): BindingsScreen
    return self._bindingsScreen
end

function ControlCustomizationView.SetVisible(self: ControlCustomizationView, isVisible: boolean): ()
    self._panel:SetVisible(isVisible)
end

function ControlCustomizationView.Destroy(self: ControlCustomizationView): ()
    self._bindingsScreen:Destroy()
    self._titleLabel:Destroy()
    self._panel:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ControlCustomizationView)
return ControlCustomizationView
