--!strict
local PresetPicker = {}
PresetPicker.__index = PresetPicker

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local UIComponents = script.Parent
local Button = require(UIComponents.Button)
local Label = require(UIComponents.Label)
local LabelStyle = require(UIComponents.LabelStyle)
local Panel = require(UIComponents.Panel)
local PanelTone = require(UIComponents.PanelTone)
local UITheme = require(UIComponents.UITheme)

type Signal = typeof(Signal)
type Button = Button.Button
type Label = Label.Label
type Panel = Panel.Panel

export type PresetOption = {
    Id: string,
    Name: string
}

export type PresetPickerProps = {
    Name: string?,
    Title: string,
    Options: {PresetOption}
}

type PresetPickerData = {
    _backdrop: Frame,
    _panel: Panel,
    _titleLabel: Label,
    _list: ScrollingFrame,
    _optionButtons: {Button},
    _cancelButton: Button,
    PresetChosen: Signal,
    Cancelled: Signal
}

export type PresetPicker = typeof(setmetatable({} :: PresetPickerData, PresetPicker))

local PANEL_SIZE = UDim2.fromOffset(320, 260)
local PANEL_PADDING = 16
local TITLE_HEIGHT = 32
local LIST_TOP = 56
local LIST_BOTTOM_GAP = 64
local OPTION_HEIGHT = 40
local OPTION_SPACING = 6
local CANCEL_SIZE = UDim2.fromOffset(120, 40)
local SCROLL_BAR_THICKNESS = 4

-- Sits over everything and takes every press, so nothing behind the picker can be touched while it is up.
local function createBackdrop(props: PresetPickerProps): Frame
    local backdrop = Instance.new("Frame")
    backdrop.Name = props.Name or "PresetPicker"
    backdrop.BorderSizePixel = 0
    backdrop.BackgroundColor3 = UITheme.Colors.Backdrop
    backdrop.BackgroundTransparency = UITheme.BackdropTransparency
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.Active = true
    backdrop.Visible = false
    return backdrop
end

local function createPanel(): Panel
    local panelProps: Panel.PanelProps = {
        Name = "Picker",
        Tone = PanelTone.Window,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = PANEL_SIZE,
    }
    return Panel.new(panelProps)
end

local function createTitleLabel(title: string): Label
    local labelProps: Label.LabelProps = {
        Name = "Title",
        Text = title,
        Style = LabelStyle.Title,
        Position = UDim2.fromOffset(PANEL_PADDING, PANEL_PADDING),
        Size = UDim2.new(1, -PANEL_PADDING * 2, 0, TITLE_HEIGHT),
    }
    return Label.new(labelProps)
end

local function createList(): ScrollingFrame
    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.Position = UDim2.fromOffset(PANEL_PADDING, LIST_TOP)
    list.Size = UDim2.new(1, -PANEL_PADDING * 2, 1, -LIST_TOP - LIST_BOTTOM_GAP)
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.CanvasSize = UDim2.new()
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollBarThickness = SCROLL_BAR_THICKNESS
    list.ScrollBarImageColor3 = UITheme.Colors.ButtonBorder

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, OPTION_SPACING)
    layout.Parent = list

    return list
end

local function createOptionButton(option: PresetOption, order: number): Button
    local buttonProps: Button.ButtonProps = {
        Name = option.Id,
        Text = option.Name,
        Size = UDim2.new(1, -SCROLL_BAR_THICKNESS * 2, 0, OPTION_HEIGHT),
        LayoutOrder = order,
    }
    return Button.new(buttonProps)
end

local function createCancelButton(): Button
    local buttonProps: Button.ButtonProps = {
        Name = "Cancel",
        Text = "Cancel",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -PANEL_PADDING, 1, -PANEL_PADDING),
        Size = CANCEL_SIZE,
    }
    return Button.new(buttonProps)
end

function PresetPicker.new(props: PresetPickerProps): PresetPicker
    local self = setmetatable({}, PresetPicker)

    self._backdrop = createBackdrop(props)
    self._panel = createPanel()
    self._titleLabel = createTitleLabel(props.Title)
    self._list = createList()
    self._optionButtons = {}
    self._cancelButton = createCancelButton()
    self.PresetChosen = Signal.new()
    self.Cancelled = Signal.new()

    self:_assemble()
    self:_addOptionButtons(props.Options)
    self._cancelButton.Activated:Connect(function()
        self.Cancelled:Fire()
    end)

    return self :: PresetPicker
end

function PresetPicker.GetGuiObject(self: PresetPicker): GuiObject
    return self._backdrop
end

function PresetPicker.Show(self: PresetPicker): ()
    self._backdrop.Visible = true
end

function PresetPicker.Hide(self: PresetPicker): ()
    self._backdrop.Visible = false
end

function PresetPicker.IsShown(self: PresetPicker): boolean
    return self._backdrop.Visible
end

function PresetPicker._assemble(self: PresetPicker): ()
    local panelObject = self._panel:GetGuiObject()
    self._titleLabel:GetGuiObject().Parent = panelObject
    self._list.Parent = panelObject
    self._cancelButton:GetGuiObject().Parent = panelObject
    panelObject.Parent = self._backdrop
end

function PresetPicker._addOptionButtons(self: PresetPicker, options: {PresetOption}): ()
    for order, option in ipairs(options) do
        local button = createOptionButton(option, order)
        button:GetGuiObject().Parent = self._list
        button.Activated:Connect(function()
            self.PresetChosen:Fire(option.Id)
        end)
        table.insert(self._optionButtons, button)
    end
end

function PresetPicker.Destroy(self: PresetPicker): ()
    self.PresetChosen:DisconnectAll()
    self.Cancelled:DisconnectAll()
    for _, button in ipairs(self._optionButtons) do
        button:Destroy()
    end
    table.clear(self._optionButtons)
    self._cancelButton:Destroy()
    self._titleLabel:Destroy()
    self._panel:Destroy()
    self._backdrop:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(PresetPicker)
return PresetPicker
