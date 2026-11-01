--!strict
local BindingRow = {}
BindingRow.__index = BindingRow

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local UIComponents = script.Parent.UIComponents
local Button = require(UIComponents.Button)
local Label = require(UIComponents.Label)
local Panel = require(UIComponents.Panel)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type Button = Button.Button
type Label = Label.Label
type Panel = Panel.Panel

export type BindingRowProps = {
    ActionName: ActionID,
    LayoutOrder: number?
}

type BindingRowData = {
    _actionName: ActionID,
    _panel: Panel,
    _nameLabel: Label,
    _bindingsLabel: Label,
    _rebindButton: Button,
    RebindRequested: Signal
}

export type BindingRow = typeof(setmetatable({} :: BindingRowData, BindingRow))

local ROW_HEIGHT = 40
local UNBOUND_TEXT = "Unbound"
local REBIND_TEXT = "Rebind"
local WAITING_TEXT = "..."

local function collectBoundNames(bindings: {[any]: boolean}): {string}
    local names: {string} = {}
    for binding, isBound in pairs(bindings) do
        if isBound then
            table.insert(names, (binding :: EnumItem).Name)
        end
    end
    return names
end

-- Names in a fixed order, since a binding set has none and the text would otherwise shuffle between renders.
local function describeBindings(bindings: {[any]: boolean}?): string
    if not bindings then
        return UNBOUND_TEXT
    end

    local names = collectBoundNames(bindings)
    if #names == 0 then
        return UNBOUND_TEXT
    end

    table.sort(names)
    return table.concat(names, ", ")
end

local function createPanel(props: BindingRowProps): Panel
    local panelProps: Panel.PanelProps = {
        Name = props.ActionName,
        Tone = "Row",
        Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
        LayoutOrder = props.LayoutOrder,
    }
    return Panel.new(panelProps)
end

local function createNameLabel(actionName: ActionID): Label
    local labelProps: Label.LabelProps = {
        Name = "ActionName",
        Text = actionName,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.25, 0, 1, 0),
    }
    return Label.new(labelProps)
end

local function createBindingsLabel(): Label
    local labelProps: Label.LabelProps = {
        Name = "Bindings",
        Text = UNBOUND_TEXT,
        Position = UDim2.fromScale(0.28, 0),
        Size = UDim2.fromScale(0.46, 1),
    }
    return Label.new(labelProps)
end

local function createRebindButton(): Button
    local buttonProps: Button.ButtonProps = {
        Name = "Rebind",
        Text = REBIND_TEXT,
        Position = UDim2.new(0.76, 0, 0, 5),
        Size = UDim2.new(0.22, 0, 1, -10),
    }
    return Button.new(buttonProps)
end

function BindingRow.new(props: BindingRowProps): BindingRow
    local self = setmetatable({}, BindingRow)

    self._actionName = props.ActionName
    self._panel = createPanel(props)
    self._nameLabel = createNameLabel(props.ActionName)
    self._bindingsLabel = createBindingsLabel()
    self._rebindButton = createRebindButton()
    self.RebindRequested = Signal.new()

    self:_parentChildrenToPanel()
    self:_forwardRebindPresses()

    return self :: BindingRow
end

function BindingRow.GetGuiObject(self: BindingRow): GuiObject
    return self._panel:GetGuiObject()
end

function BindingRow.SetBindings(self: BindingRow, bindings: {[any]: boolean}?): ()
    self._bindingsLabel:SetText(describeBindings(bindings))
end

function BindingRow.SetCapturing(self: BindingRow, isCapturing: boolean): ()
    self._rebindButton:SetText(if isCapturing then WAITING_TEXT else REBIND_TEXT)
    self._panel:SetTone(if isCapturing then "RowHighlighted" else "Row")
end

function BindingRow._parentChildrenToPanel(self: BindingRow): ()
    local panelObject = self._panel:GetGuiObject()
    self._nameLabel:GetGuiObject().Parent = panelObject
    self._bindingsLabel:GetGuiObject().Parent = panelObject
    self._rebindButton:GetGuiObject().Parent = panelObject
end

function BindingRow._forwardRebindPresses(self: BindingRow): ()
    self._rebindButton.Activated:Connect(function()
        self.RebindRequested:Fire(self._actionName)
    end)
end

function BindingRow.Destroy(self: BindingRow): ()
    self.RebindRequested:DisconnectAll()
    self._rebindButton:Destroy()
    self._bindingsLabel:Destroy()
    self._nameLabel:Destroy()
    self._panel:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BindingRow)
return BindingRow
