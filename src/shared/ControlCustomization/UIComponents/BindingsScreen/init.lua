--!strict
local BindingsScreen = {}
BindingsScreen.__index = BindingsScreen

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)
local BindingRow = require(script.Parent.BindingRow)
local UIComponents = script.Parent
local AppBar = require(UIComponents.AppBar)
local Button = require(UIComponents.Button)
local Label = require(UIComponents.Label)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type InputDevice = InputDevice.InputDevice
type InputScheme = InputSchemeTypes.InputScheme
type InputBinding = InputSchemeTypes.InputBinding
type BindingRow = BindingRow.BindingRow
type AppBar = AppBar.AppBar
type Button = Button.Button
type Label = Label.Label
type LabelProps = Label.LabelProps
type AppBarProps = AppBar.AppBarProps
type ButtonProps = Button.ButtonProps
type BindingRowProps = BindingRow.BindingRowProps

type BindingsScreenData = {
    _root: Frame,
    _appBar: AppBar,
    _promptLabel: Label,
    _resetButton: Button,
    _exitButton: Button,
    _rows: {[ActionID]: BindingRow},
    OnRebindRequested: Signal,
    OnUnbindRequested: Signal,
    OnResetRequested: Signal,
    OnExitRequested: Signal
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

-- The device values are lowercase for storage, so the title needs its own wording.
local DEVICE_NAMES: {[InputDevice]: string} = {
    [InputDevice.Keyboard] = "Keyboard",
    [InputDevice.Gamepad] = "Gamepad",
    [InputDevice.Touch] = "Touch",
}

local APP_BAR_ORDER = 0
local PROMPT_ORDER = 100
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

local function createAppBar(): AppBar
    local appBarProps: AppBarProps = {
        Name = "AppBar",
        LayoutOrder = APP_BAR_ORDER,
    }
    return AppBar.new(appBarProps)
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
        Size = UDim2.fromOffset(160, 32),
    }
    return Button.new(buttonProps)
end

local function createExitButton(): Button
    local buttonProps: ButtonProps = {
        Name = "Exit",
        Text = "Exit",
        Size = UDim2.fromOffset(80, 32),
    }
    return Button.new(buttonProps)
end

function BindingsScreen.new(parent: Instance): BindingsScreen
    local self = setmetatable({}, BindingsScreen)

    self._root = createRoot(parent)
    self._rows = {}
    self._appBar = createAppBar()
    self._promptLabel = createPromptLabel()
    self._resetButton = createResetButton()
    self._exitButton = createExitButton()
    self.OnRebindRequested = Signal.new()
    self.OnUnbindRequested = Signal.new()
    self.OnResetRequested = Signal.new()
    self.OnExitRequested = Signal.new()

    self:_buildRows()
    self:_parentAppBarAndPrompt()
    self:_addButtonsToAppBar()
    self:_forwardResetPresses()
    self:_forwardExitPresses()

    return self :: BindingsScreen
end

function BindingsScreen.Render(self: BindingsScreen, device: InputDevice, scheme: InputScheme): ()
    self._appBar:SetTitle((DEVICE_NAMES[device] or "Unknown") .. " controls")

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
        row.BindingDeleteRequested:Connect(function(requestedAction: ActionID, binding: InputBinding)
            self.OnUnbindRequested:Fire(requestedAction, binding)
        end)
        self._rows[actionName] = row
    end
end

function BindingsScreen._parentAppBarAndPrompt(self: BindingsScreen): ()
    self._appBar:GetGuiObject().Parent = self._root
    self._promptLabel:GetGuiObject().Parent = self._root
end

function BindingsScreen._addButtonsToAppBar(self: BindingsScreen): ()
    self._appBar:AddAction(self._resetButton:GetGuiObject())
    self._appBar:AddAction(self._exitButton:GetGuiObject())
end

function BindingsScreen._forwardResetPresses(self: BindingsScreen): ()
    self._resetButton.Activated:Connect(function()
        self.OnResetRequested:Fire()
    end)
end

function BindingsScreen._forwardExitPresses(self: BindingsScreen): ()
    self._exitButton.Activated:Connect(function()
        self.OnExitRequested:Fire()
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
    self._exitButton:Destroy()
    self._resetButton:Destroy()
    self._promptLabel:Destroy()
    self._appBar:Destroy()
    self.OnRebindRequested:DisconnectAll()
    self.OnUnbindRequested:DisconnectAll()
    self.OnResetRequested:DisconnectAll()
    self.OnExitRequested:DisconnectAll()
    self._root:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BindingsScreen)
return BindingsScreen
