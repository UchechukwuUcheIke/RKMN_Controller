--!strict
local ConfirmDialog = {}
ConfirmDialog.__index = ConfirmDialog

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

export type DialogChoice = {
    Id: string,
    Text: string
}

export type ConfirmDialogProps = {
    Name: string?,
    Title: string,
    Message: string,
    Choices: {DialogChoice}
}

type ConfirmDialogData = {
    _backdrop: Frame,
    _panel: Panel,
    _titleLabel: Label,
    _messageLabel: Label,
    _buttonRow: Frame,
    _buttons: {Button},
    ChoiceMade: Signal
}

export type ConfirmDialog = typeof(setmetatable({} :: ConfirmDialogData, ConfirmDialog))

local PANEL_SIZE = UDim2.fromOffset(380, 190)
local PANEL_PADDING = 16
local TITLE_HEIGHT = 32
local MESSAGE_TOP = 56
local MESSAGE_HEIGHT = 56
local BUTTON_ROW_HEIGHT = 40
local BUTTON_WIDTH = 104
local BUTTON_SPACING = 8

local function createBackdrop(props: ConfirmDialogProps): Frame
    local backdrop = Instance.new("Frame")
    backdrop.Name = props.Name or "ConfirmDialog"
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
        Name = "Dialog",
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

local function createMessageLabel(message: string): Label
    local labelProps: Label.LabelProps = {
        Name = "Message",
        Text = message,
        Position = UDim2.fromOffset(PANEL_PADDING, MESSAGE_TOP),
        Size = UDim2.new(1, -PANEL_PADDING * 2, 0, MESSAGE_HEIGHT),
        Wrapped = true,
    }
    return Label.new(labelProps)
end

local function createButtonRow(): Frame
    local row = Instance.new("Frame")
    row.Name = "Buttons"
    row.BackgroundTransparency = 1
    row.AnchorPoint = Vector2.new(0, 1)
    row.Position = UDim2.new(0, PANEL_PADDING, 1, -PANEL_PADDING)
    row.Size = UDim2.new(1, -PANEL_PADDING * 2, 0, BUTTON_ROW_HEIGHT)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, BUTTON_SPACING)
    layout.Parent = row

    return row
end

local function createChoiceButton(choice: DialogChoice, order: number): Button
    local buttonProps: Button.ButtonProps = {
        Name = choice.Id,
        Text = choice.Text,
        Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_ROW_HEIGHT),
        LayoutOrder = order,
    }
    return Button.new(buttonProps)
end

function ConfirmDialog.new(props: ConfirmDialogProps): ConfirmDialog
    local self = setmetatable({}, ConfirmDialog)

    self._backdrop = createBackdrop(props)
    self._panel = createPanel()
    self._titleLabel = createTitleLabel(props.Title)
    self._messageLabel = createMessageLabel(props.Message)
    self._buttonRow = createButtonRow()
    self._buttons = {}
    self.ChoiceMade = Signal.new()

    self:_assemble()
    self:_addChoiceButtons(props.Choices)

    return self :: ConfirmDialog
end

function ConfirmDialog.GetGuiObject(self: ConfirmDialog): GuiObject
    return self._backdrop
end

function ConfirmDialog.Show(self: ConfirmDialog): ()
    self._backdrop.Visible = true
end

function ConfirmDialog.Hide(self: ConfirmDialog): ()
    self._backdrop.Visible = false
end

function ConfirmDialog.IsShown(self: ConfirmDialog): boolean
    return self._backdrop.Visible
end

function ConfirmDialog._assemble(self: ConfirmDialog): ()
    local panelObject = self._panel:GetGuiObject()
    self._titleLabel:GetGuiObject().Parent = panelObject
    self._messageLabel:GetGuiObject().Parent = panelObject
    self._buttonRow.Parent = panelObject
    panelObject.Parent = self._backdrop
end

function ConfirmDialog._addChoiceButtons(self: ConfirmDialog, choices: {DialogChoice}): ()
    for order, choice in ipairs(choices) do
        local button = createChoiceButton(choice, order)
        button:GetGuiObject().Parent = self._buttonRow
        button.Activated:Connect(function()
            self.ChoiceMade:Fire(choice.Id)
        end)
        table.insert(self._buttons, button)
    end
end

function ConfirmDialog.Destroy(self: ConfirmDialog): ()
    self.ChoiceMade:DisconnectAll()
    for _, button in ipairs(self._buttons) do
        button:Destroy()
    end
    table.clear(self._buttons)
    self._messageLabel:Destroy()
    self._titleLabel:Destroy()
    self._panel:Destroy()
    self._backdrop:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ConfirmDialog)
return ConfirmDialog
