--!strict
local BugReportScreen = {}
BugReportScreen.__index = BugReportScreen

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local BugReportDraft = require(ReplicatedStorage.Telemetry.BugReport.BugReportDraft)
local UIComponents = ReplicatedStorage.ControlCustomization.UIComponents
local AppBar = require(UIComponents.AppBar)
local Button = require(UIComponents.Button)
local Label = require(UIComponents.Label)
local Panel = require(UIComponents.Panel)
local PanelTone = require(UIComponents.PanelTone)
local TextInput = require(UIComponents.TextInput)

type Signal = typeof(Signal)
type AppBar = AppBar.AppBar
type Button = Button.Button
type Label = Label.Label
type Panel = Panel.Panel
type TextInput = TextInput.TextInput

type BugReportScreenData = {
    _screenGui: ScreenGui,
    _panel: Panel,
    _content: Frame,
    _appBar: AppBar,
    _sendButton: Button,
    _cancelButton: Button,
    _descriptionInput: TextInput,
    _statusLabel: Label,
    OnSubmitRequested: Signal,
    OnCancelRequested: Signal
}

export type BugReportScreen = typeof(setmetatable({} :: BugReportScreenData, BugReportScreen))

-- Above the touch gamepad and the controls panel, so the report is never covered by them.
local DISPLAY_ORDER = 10
local PANEL_SIZE = UDim2.fromOffset(520, 300)
local PANEL_PADDING = 16
local ELEMENT_SPACING = 8
local APP_BAR_ORDER = 0
local INPUT_ORDER = 1
local STATUS_ORDER = 2
local INPUT_HEIGHT = 150
local STATUS_HEIGHT = 40
local PLACEHOLDER = "What went wrong? What were you doing when it happened?"

local function createScreenGui(parent: Instance): ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BugReportScreen"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = DISPLAY_ORDER
    screenGui.Parent = parent
    return screenGui
end

local function createPanel(screenGui: ScreenGui): Panel
    local panelProps: Panel.PanelProps = {
        Name = "Window",
        Tone = PanelTone.Window,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = PANEL_SIZE,
        Visible = false,
    }
    local panel = Panel.new(panelProps)
    panel:GetGuiObject().Parent = screenGui
    return panel
end

local function createContent(panel: Panel): Frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.fromScale(1, 1)
    content.Parent = panel:GetGuiObject()

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, PANEL_PADDING)
    padding.PaddingRight = UDim.new(0, PANEL_PADDING)
    padding.PaddingTop = UDim.new(0, PANEL_PADDING)
    padding.PaddingBottom = UDim.new(0, PANEL_PADDING)
    padding.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, ELEMENT_SPACING)
    layout.Parent = content

    return content
end

local function createAppBar(): AppBar
    local appBarProps: AppBar.AppBarProps = {
        Name = "AppBar",
        Title = "Report a bug",
        LayoutOrder = APP_BAR_ORDER,
    }
    return AppBar.new(appBarProps)
end

local function createSendButton(): Button
    local buttonProps: Button.ButtonProps = {
        Name = "Send",
        Text = "Send",
        Size = UDim2.fromOffset(80, 32),
    }
    return Button.new(buttonProps)
end

local function createCancelButton(): Button
    local buttonProps: Button.ButtonProps = {
        Name = "Cancel",
        Text = "Cancel",
        Size = UDim2.fromOffset(80, 32),
    }
    return Button.new(buttonProps)
end

local function createDescriptionInput(): TextInput
    local inputProps: TextInput.TextInputProps = {
        Name = "Description",
        PlaceholderText = PLACEHOLDER,
        Size = UDim2.new(1, 0, 0, INPUT_HEIGHT),
        LayoutOrder = INPUT_ORDER,
        MaxLength = BugReportDraft.MAX_DESCRIPTION_LENGTH,
    }
    return TextInput.new(inputProps)
end

local function createStatusLabel(): Label
    local labelProps: Label.LabelProps = {
        Name = "Status",
        Size = UDim2.new(1, 0, 0, STATUS_HEIGHT),
        LayoutOrder = STATUS_ORDER,
        Wrapped = true,
    }
    return Label.new(labelProps)
end

function BugReportScreen.new(parent: Instance): BugReportScreen
    local self = setmetatable({}, BugReportScreen)

    self._screenGui = createScreenGui(parent)
    self._panel = createPanel(self._screenGui)
    self._content = createContent(self._panel)
    self._appBar = createAppBar()
    self._sendButton = createSendButton()
    self._cancelButton = createCancelButton()
    self._descriptionInput = createDescriptionInput()
    self._statusLabel = createStatusLabel()
    self.OnSubmitRequested = Signal.new()
    self.OnCancelRequested = Signal.new()

    self:_parentElements()
    self:_addButtonsToAppBar()
    self:_forwardSendPresses()
    self:_forwardCancelPresses()

    return self :: BugReportScreen
end

function BugReportScreen.SetVisible(self: BugReportScreen, isVisible: boolean): ()
    self._panel:SetVisible(isVisible)
end

function BugReportScreen.SetStatus(self: BugReportScreen, text: string): ()
    self._statusLabel:SetText(text)
end

-- While a report is on its way, nothing can be edited, resent or cancelled.
function BugReportScreen.SetSending(self: BugReportScreen, isSending: boolean): ()
    if isSending then
        self._descriptionInput:Disable()
        self._sendButton:Disable()
        self._cancelButton:Disable()
    else
        self._descriptionInput:Enable()
        self._sendButton:Enable()
        self._cancelButton:Enable()
    end
end

function BugReportScreen.Clear(self: BugReportScreen): ()
    self._descriptionInput:SetText("")
    self._statusLabel:SetText("")
end

function BugReportScreen._parentElements(self: BugReportScreen): ()
    self._appBar:GetGuiObject().Parent = self._content
    self._descriptionInput:GetGuiObject().Parent = self._content
    self._statusLabel:GetGuiObject().Parent = self._content
end

function BugReportScreen._addButtonsToAppBar(self: BugReportScreen): ()
    self._appBar:AddAction(self._sendButton:GetGuiObject())
    self._appBar:AddAction(self._cancelButton:GetGuiObject())
end

function BugReportScreen._forwardSendPresses(self: BugReportScreen): ()
    self._sendButton.Activated:Connect(function()
        self.OnSubmitRequested:Fire(self._descriptionInput:GetText())
    end)
end

function BugReportScreen._forwardCancelPresses(self: BugReportScreen): ()
    self._cancelButton.Activated:Connect(function()
        self.OnCancelRequested:Fire()
    end)
end

function BugReportScreen.Destroy(self: BugReportScreen): ()
    self._cancelButton:Destroy()
    self._sendButton:Destroy()
    self._descriptionInput:Destroy()
    self._statusLabel:Destroy()
    self._appBar:Destroy()
    self.OnSubmitRequested:DisconnectAll()
    self.OnCancelRequested:DisconnectAll()
    self._panel:Destroy()
    self._screenGui:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BugReportScreen)
return BugReportScreen
