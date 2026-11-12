--!strict
local BugReportButton = {}
BugReportButton.__index = BugReportButton

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local Button = require(ReplicatedStorage.ControlCustomization.UIComponents.Button)

type Signal = typeof(Signal)
type Button = Button.Button

type BugReportButtonData = {
    _screenGui: ScreenGui,
    _button: Button,
    Activated: Signal
}

export type BugReportButton = typeof(setmetatable({} :: BugReportButtonData, BugReportButton))

local BUTTON_SIZE = UDim2.fromOffset(110, 32)
local SCREEN_MARGIN = 12
local BACKGROUND_TRANSPARENCY = 0.35

-- Mounted below Roblox's top bar (IgnoreGuiInset stays false), in the top-right corner.
local function createScreenGui(parent: Instance): ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BugReportButton"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = parent
    return screenGui
end

local function createButton(screenGui: ScreenGui): Button
    local buttonProps: Button.ButtonProps = {
        Name = "ReportBug",
        Text = "Report bug",
        Size = BUTTON_SIZE,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -SCREEN_MARGIN, 0, SCREEN_MARGIN),
    }
    local button = Button.new(buttonProps)

    local guiObject = button:GetGuiObject()
    guiObject.BackgroundTransparency = BACKGROUND_TRANSPARENCY
    guiObject.Parent = screenGui

    return button
end

function BugReportButton.new(parent: Instance): BugReportButton
    local self = setmetatable({}, BugReportButton)

    self._screenGui = createScreenGui(parent)
    self._button = createButton(self._screenGui)
    self.Activated = Signal.new()

    self:_forwardPresses()

    return self :: BugReportButton
end

function BugReportButton.SetVisible(self: BugReportButton, isVisible: boolean): ()
    self._screenGui.Enabled = isVisible
end

function BugReportButton._forwardPresses(self: BugReportButton): ()
    self._button.Activated:Connect(function()
        self.Activated:Fire()
    end)
end

function BugReportButton.Destroy(self: BugReportButton): ()
    self._button:Destroy()
    self.Activated:DisconnectAll()
    self._screenGui:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BugReportButton)
return BugReportButton
