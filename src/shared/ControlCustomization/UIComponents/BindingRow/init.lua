--!strict
local BindingRow = {}
BindingRow.__index = BindingRow

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local InputSchemeTypes = require(ReplicatedStorage.PlayerInput.InputScheme)
local BindingItem = require(script.Parent.BindingItem)
local UIComponents = script.Parent
local Button = require(UIComponents.Button)
local UITheme = require(UIComponents.UITheme)
local Label = require(UIComponents.Label)
local Panel = require(UIComponents.Panel)
local PanelTone = require(UIComponents.PanelTone)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type InputBinding = InputSchemeTypes.InputBinding
type BindingItem = BindingItem.BindingItem
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
    _itemsContainer: ScrollingFrame,
    _items: {BindingItem},
    _unboundLabel: Label?,
    _rebindButton: Button,
    RebindRequested: Signal,
    BindingDeleteRequested: Signal
}

export type BindingRow = typeof(setmetatable({} :: BindingRowData, BindingRow))

local ROW_HEIGHT = 40
local ITEM_SPACING = 6
local SCROLL_BAR_THICKNESS = 4
local UNBOUND_TEXT = "Unbound"
local REBIND_TEXT = "Add Binding"
local WAITING_TEXT = "..."


local function collectBoundBindings(bindings: {[any]: boolean}): {InputBinding}
    local boundBindings: {InputBinding} = {}
    for binding, isBound in pairs(bindings) do
        if isBound then
            table.insert(boundBindings, binding :: InputBinding)
        end
    end

    table.sort(boundBindings, function(first: InputBinding, second: InputBinding)
        return first.Name < second.Name
    end)
    return boundBindings
end

local function createPanel(props: BindingRowProps): Panel
    local panelProps: Panel.PanelProps = {
        Name = props.ActionName,
        Tone = PanelTone.Row,
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
        Size = UDim2.new(0.2, 0, 1, 0),
    }
    return Label.new(labelProps)
end

local function createItemsContainer(): ScrollingFrame
    local container = Instance.new("ScrollingFrame")
    container.Name = "Bindings"
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Position = UDim2.fromScale(0.22, 0)
    container.Size = UDim2.fromScale(0.54, 1)
    container.ScrollingDirection = Enum.ScrollingDirection.X
    container.CanvasSize = UDim2.new()
    container.AutomaticCanvasSize = Enum.AutomaticSize.X
    container.ScrollBarThickness = SCROLL_BAR_THICKNESS
    container.ScrollBarImageColor3 = UITheme.Colors.ButtonBorder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, ITEM_SPACING)
    layout.Parent = container

    return container
end

local function createRebindButton(): Button
    local buttonProps: Button.ButtonProps = {
        Name = "Rebind",
        Text = REBIND_TEXT,
        Position = UDim2.new(0.78, 0, 0, 5),
        Size = UDim2.new(0.2, 0, 1, -10),
    }
    return Button.new(buttonProps)
end

local function createUnboundLabel(): Label
    local labelProps: Label.LabelProps = {
        Name = "Unbound",
        Text = UNBOUND_TEXT,
        Size = UDim2.fromOffset(100, ROW_HEIGHT),
    }
    return Label.new(labelProps)
end

function BindingRow.new(props: BindingRowProps): BindingRow
    local self = setmetatable({}, BindingRow)

    self._actionName = props.ActionName
    self._panel = createPanel(props)
    self._nameLabel = createNameLabel(props.ActionName)
    self._itemsContainer = createItemsContainer()
    self._items = {}
    self._unboundLabel = nil
    self._rebindButton = createRebindButton()
    self.RebindRequested = Signal.new()
    self.BindingDeleteRequested = Signal.new()

    self:_parentChildrenToPanel()
    self:_forwardRebindPresses()
    self:_showUnboundLabel()

    return self :: BindingRow
end

function BindingRow.GetGuiObject(self: BindingRow): GuiObject
    return self._panel:GetGuiObject()
end

function BindingRow.SetBindings(self: BindingRow, bindings: {[any]: boolean}?): ()
    self:_clearBindingDisplay()

    local boundBindings = if bindings then collectBoundBindings(bindings) else {}
    if #boundBindings == 0 then
        self:_showUnboundLabel()
        return
    end

    for index, binding in ipairs(boundBindings) do
        self:_addItem(binding, index)
    end
end

function BindingRow.SetCapturing(self: BindingRow, isCapturing: boolean): ()
    self._rebindButton:SetText(if isCapturing then WAITING_TEXT else REBIND_TEXT)
    self._panel:SetTone(if isCapturing then PanelTone.RowHighlighted else PanelTone.Row)
end

function BindingRow._parentChildrenToPanel(self: BindingRow): ()
    local panelObject = self._panel:GetGuiObject()
    self._nameLabel:GetGuiObject().Parent = panelObject
    self._itemsContainer.Parent = panelObject
    self._rebindButton:GetGuiObject().Parent = panelObject
end

function BindingRow._forwardRebindPresses(self: BindingRow): ()
    self._rebindButton.Activated:Connect(function()
        self.RebindRequested:Fire(self._actionName)
    end)
end

function BindingRow._addItem(self: BindingRow, binding: InputBinding, order: number): ()
    local itemProps: BindingItem.BindingItemProps = {
        Binding = binding,
        LayoutOrder = order,
    }
    local item = BindingItem.new(itemProps)
    item:GetGuiObject().Parent = self._itemsContainer
    item.DeleteRequested:Connect(function(deletedBinding: InputBinding)
        self.BindingDeleteRequested:Fire(self._actionName, deletedBinding)
    end)
    table.insert(self._items, item)
end

function BindingRow._showUnboundLabel(self: BindingRow): ()
    local unboundLabel = createUnboundLabel()
    unboundLabel:GetGuiObject().Parent = self._itemsContainer
    self._unboundLabel = unboundLabel
end

function BindingRow._clearBindingDisplay(self: BindingRow): ()
    for _, item in ipairs(self._items) do
        item:Destroy()
    end
    table.clear(self._items)

    if self._unboundLabel then
        self._unboundLabel:Destroy()
        self._unboundLabel = nil
    end
end

function BindingRow.Destroy(self: BindingRow): ()
    self:_clearBindingDisplay()
    self.RebindRequested:DisconnectAll()
    self.BindingDeleteRequested:DisconnectAll()
    self._rebindButton:Destroy()
    self._nameLabel:Destroy()
    self._itemsContainer:Destroy()
    self._panel:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BindingRow)
return BindingRow
