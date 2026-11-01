--!strict
local BindingsScreen = {}
BindingsScreen.__index = BindingsScreen

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputDevice = require(PlayerInputFolder.InputDevice)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)
local BindingRow = require(script.Parent.BindingRow)
local UIComponents = script.Parent.UIComponents
local Button = require(UIComponents.Button)
local Label = require(UIComponents.Label)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type InputDevice = InputDevice.InputDevice
type InputScheme = InputSchemeTypes.InputScheme
type BindingRow = BindingRow.BindingRow
type Button = Button.Button
type Label = Label.Label
type LabelProps = Label.LabelProps
type ButtonProps = Button.ButtonProps
type BindingRowProps = BindingRow.BindingRowProps

type BindingsScreenData = {
    _root: Frame,
    _titleLabel: Label,
    _promptLabel: Label,
    _resetButton: Button,
    _rows: {[ActionID]: BindingRow},
    OnRebindRequested: Signal,
    OnResetRequested: Signal
}

export type BindingsScreen = typeof(setmetatable({} :: BindingsScreenData, BindingsScreen))

-- TODO: I'm not a fan of this hardcoded approach. Consider other options: converting ActionIDs to a list on require time?
-- Alternatively, this hardcoded order means we can reason about what order each control appears in the UI
local ROW_ORDER: {ActionID} = {
    InputAction.Left,
    InputAction.Right,
    InputAction.Jump,
    InputAction.Dash,
    InputAction.Shoot,
    InputAction.Menu,
}

local TITLE_ORDER = 0
local PROMPT_ORDER = 100
local RESET_ORDER = 101
local ROW_SPACING = 6

local function createRoot(parent: Instance): Frame
    local root = Instance.new("Frame")
    root.Name = "BindingsScreen"
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, ROW_SPACING)
    layout.Parent = root

    return root
end

local function createTitleLabel(): Label
    local labelProps: LabelProps = {
        Name = "Title",
        LayoutOrder = TITLE_ORDER,
    }
    return Label.new(labelProps)
end

local function createPromptLabel(): Label
    local labelProps: LabelProps = {
        Name = "Prompt",
        Size = UDim2.new(1, 0, 0, 24),
        LayoutOrder = PROMPT_ORDER,
    }
    return Label.new(labelProps)
end

local function createResetButton(): Button
    local buttonProps: ButtonProps = {
        Name = "Reset",
        Text = "Reset to defaults",
        Size = UDim2.fromOffset(160, 40),
        LayoutOrder = RESET_ORDER,
    }
    return Button.new(buttonProps)
end

function BindingsScreen.new(parent: Instance): BindingsScreen
    local self = setmetatable({}, BindingsScreen)

    self._root = createRoot(parent)
    self._rows = {}
    self._titleLabel = createTitleLabel()
    self._promptLabel = createPromptLabel()
    self._resetButton = createResetButton()
    self.OnRebindRequested = Signal.new()
    self.OnResetRequested = Signal.new()

    self:_buildRows()
    self:_parentLabelsAndResetButton()
    self:_forwardResetPresses()

    return self :: BindingsScreen
end

function BindingsScreen.Render(self: BindingsScreen, device: InputDevice, scheme: InputScheme): ()
    self._titleLabel:SetText(device .. " controls")

    for _, actionName in ipairs(ROW_ORDER) do
        self._rows[actionName]:SetBindings(scheme[actionName])
    end
end

function BindingsScreen.SetCapturing(self: BindingsScreen, actionName: ActionID?, cancelKeyName: string?): ()
    for rowAction, row in pairs(self._rows) do
        row:SetCapturing(rowAction == actionName)
    end

    self._promptLabel:SetText(self:_describeCapturePrompt(actionName, cancelKeyName))
end

function BindingsScreen.SetVisible(self: BindingsScreen, isVisible: boolean): ()
    self._root.Visible = isVisible
end

function BindingsScreen._describeCapturePrompt(self: BindingsScreen, actionName: ActionID?, cancelKeyName: string?): string
    if not actionName then
        return ""
    end
    return `Press a button for {actionName} ({cancelKeyName or "Escape"} cancels)`
end

function BindingsScreen._buildRows(self: BindingsScreen): ()
    for index, actionName in ipairs(ROW_ORDER) do
        local rowProps: BindingRowProps = {
            ActionName = actionName,
            LayoutOrder = index,
        }
        local row = BindingRow.new(rowProps)
        row:GetGuiObject().Parent = self._root
        row.RebindRequested:Connect(function(requestedAction: ActionID)
            self.OnRebindRequested:Fire(requestedAction)
        end)
        self._rows[actionName] = row
    end
end

function BindingsScreen._parentLabelsAndResetButton(self: BindingsScreen): ()
    self._titleLabel:GetGuiObject().Parent = self._root
    self._promptLabel:GetGuiObject().Parent = self._root
    self._resetButton:GetGuiObject().Parent = self._root
end

function BindingsScreen._forwardResetPresses(self: BindingsScreen): ()
    self._resetButton.Activated:Connect(function()
        self.OnResetRequested:Fire()
    end)
end

function BindingsScreen._destroyRows(self: BindingsScreen): ()
    for _, row in pairs(self._rows) do
        row:Destroy()
    end
    table.clear(self._rows)
end

function BindingsScreen.Destroy(self: BindingsScreen): ()
    self:_destroyRows()
    self._resetButton:Destroy()
    self._promptLabel:Destroy()
    self._titleLabel:Destroy()
    self.OnRebindRequested:DisconnectAll()
    self.OnResetRequested:DisconnectAll()
    self._root:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BindingsScreen)
return BindingsScreen
