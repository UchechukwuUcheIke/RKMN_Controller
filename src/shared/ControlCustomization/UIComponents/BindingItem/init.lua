--!strict
local BindingItem = {}
BindingItem.__index = BindingItem

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputSchemeTypes = require(ReplicatedStorage.PlayerInput.InputScheme)
local BindingIcons = require(script.Parent.BindingIcons)
local UIComponents = script.Parent
local Button = require(UIComponents.Button)
local FallbackImage = require(UIComponents.FallbackImage)
local Label = require(UIComponents.Label)
local Panel = require(UIComponents.Panel)
local PanelTone = require(UIComponents.PanelTone)

type Signal = typeof(Signal)
type InputBinding = InputSchemeTypes.InputBinding
type Button = Button.Button
type FallbackImage = FallbackImage.FallbackImage
type Label = Label.Label
type Panel = Panel.Panel

export type BindingItemProps = {
    Binding: InputBinding,
    LayoutOrder: number?
}

type BindingItemData = {
    _binding: InputBinding,
    _panel: Panel,
    _content: Frame,
    _image: FallbackImage,
    _nameLabel: Label,
    _deleteButton: Button,
    _isItemHovered: boolean,
    _isDeleteButtonHovered: boolean,
    _connections: {RBXScriptConnection},
    DeleteRequested: Signal
}

export type BindingItem = typeof(setmetatable({} :: BindingItemData, BindingItem))

local ITEM_HEIGHT = 32
local IMAGE_SIZE = 24
local CONTENT_SPACING = 6
local PADDING_LEFT = 4
local PADDING_RIGHT = 26
local DELETE_BUTTON_SIZE = 18
local DELETE_BUTTON_INSET = 3

local function createPanel(props: BindingItemProps): Panel
    local panelProps: Panel.PanelProps = {
        Name = props.Binding.Name,
        Tone = PanelTone.Item,
        Size = UDim2.fromOffset(0, ITEM_HEIGHT),
        LayoutOrder = props.LayoutOrder,
    }
    local panel = Panel.new(panelProps)
    panel:GetGuiObject().AutomaticSize = Enum.AutomaticSize.X
    return panel
end

local function createContent(): Frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.fromScale(0, 1)
    content.AutomaticSize = Enum.AutomaticSize.X

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, CONTENT_SPACING)
    layout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, PADDING_LEFT)
    padding.PaddingRight = UDim.new(0, PADDING_RIGHT)
    padding.Parent = content

    return content
end

local function createImage(binding: InputBinding): FallbackImage
    local imageProps: FallbackImage.FallbackImageProps = {
        ImageId = BindingIcons.GetImageId(binding),
        FallbackText = binding.Name,
        Size = UDim2.fromOffset(IMAGE_SIZE, IMAGE_SIZE),
        LayoutOrder = 1,
    }
    return FallbackImage.new(imageProps)
end

local function createNameLabel(binding: InputBinding): Label
    local labelProps: Label.LabelProps = {
        Name = "BindingName",
        Text = binding.Name,
        Size = UDim2.fromOffset(0, IMAGE_SIZE),
        LayoutOrder = 2,
    }
    local label = Label.new(labelProps)
    label:GetGuiObject().AutomaticSize = Enum.AutomaticSize.X
    return label
end

local function createDeleteButton(): Button
    local buttonProps: Button.ButtonProps = {
        Name = "Delete",
        Text = "X",
        Size = UDim2.fromOffset(DELETE_BUTTON_SIZE, DELETE_BUTTON_SIZE),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -DELETE_BUTTON_INSET, 0, DELETE_BUTTON_INSET),
    }
    local button = Button.new(buttonProps)
    button:GetGuiObject().Visible = false
    return button
end

function BindingItem.new(props: BindingItemProps): BindingItem
    local self = setmetatable({}, BindingItem)

    self._binding = props.Binding
    self._panel = createPanel(props)
    self._content = createContent()
    self._image = createImage(props.Binding)
    self._nameLabel = createNameLabel(props.Binding)
    self._deleteButton = createDeleteButton()
    self._isItemHovered = false
    self._isDeleteButtonHovered = false
    self._connections = {}
    self.DeleteRequested = Signal.new()

    self:_parentChildren()
    self:_subscribeToHover()
    self:_forwardDeletePresses()

    return self :: BindingItem
end

function BindingItem.GetGuiObject(self: BindingItem): GuiObject
    return self._panel:GetGuiObject()
end

function BindingItem.GetBinding(self: BindingItem): InputBinding
    return self._binding
end

function BindingItem._parentChildren(self: BindingItem): ()
    self._image:GetGuiObject().Parent = self._content
    self._nameLabel:GetGuiObject().Parent = self._content

    local panelObject = self._panel:GetGuiObject()
    self._content.Parent = panelObject
    self._deleteButton:GetGuiObject().Parent = panelObject
end

function BindingItem._subscribeToHover(self: BindingItem): ()
    local panelObject = self._panel:GetGuiObject()
    local deleteObject = self._deleteButton:GetGuiObject()

    self:_addConnection(panelObject.MouseEnter, function() self:_handleItemHoverChanged(true) end)
    self:_addConnection(panelObject.MouseLeave, function() self:_handleItemHoverChanged(false) end)
    -- The button sits on top of the item, so the item can report the mouse leaving while it is over the button.
    self:_addConnection(deleteObject.MouseEnter, function() self:_handleDeleteButtonHoverChanged(true) end)
    self:_addConnection(deleteObject.MouseLeave, function() self:_handleDeleteButtonHoverChanged(false) end)
end

function BindingItem._addConnection(self: BindingItem, signal: RBXScriptSignal, handler: () -> ()): ()
    table.insert(self._connections, signal:Connect(handler))
end

function BindingItem._forwardDeletePresses(self: BindingItem): ()
    self._deleteButton.Activated:Connect(function()
        self.DeleteRequested:Fire(self._binding)
    end)
end

function BindingItem._handleItemHoverChanged(self: BindingItem, isHovered: boolean): ()
    self._isItemHovered = isHovered
    self:_renderDeleteButtonVisibility()
end

function BindingItem._handleDeleteButtonHoverChanged(self: BindingItem, isHovered: boolean): ()
    self._isDeleteButtonHovered = isHovered
    self:_renderDeleteButtonVisibility()
end

function BindingItem._renderDeleteButtonVisibility(self: BindingItem): ()
    self._deleteButton:GetGuiObject().Visible = self._isItemHovered or self._isDeleteButtonHovered
end

function BindingItem._destroyConnections(self: BindingItem): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function BindingItem.Destroy(self: BindingItem): ()
    self:_destroyConnections()
    self.DeleteRequested:DisconnectAll()
    self._deleteButton:Destroy()
    self._nameLabel:Destroy()
    self._image:Destroy()
    self._content:Destroy()
    self._panel:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BindingItem)
return BindingItem
