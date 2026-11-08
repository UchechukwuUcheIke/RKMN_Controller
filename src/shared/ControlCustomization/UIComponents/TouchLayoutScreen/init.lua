--!strict
local TouchLayoutScreen = {}
TouchLayoutScreen.__index = TouchLayoutScreen

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local UIComponents = script.Parent
local AppBar = require(UIComponents.AppBar)
local Button = require(UIComponents.Button)
local ControlAdjustmentPanel = require(UIComponents.ControlAdjustmentPanel)
local TouchLayoutCanvas = require(UIComponents.TouchLayoutCanvas)
local UITheme = require(UIComponents.UITheme)

type Signal = typeof(Signal)
type ControlID = TouchGamepadLayoutRegistry.ControlID
type ButtonTransform = TouchGamepadLayoutRegistry.ButtonTransform
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout
type AppBar = AppBar.AppBar
type Button = Button.Button
type ControlAdjustmentPanel = ControlAdjustmentPanel.ControlAdjustmentPanel
type TouchLayoutCanvas = TouchLayoutCanvas.TouchLayoutCanvas

export type EditState = {
    CanUndo: boolean,
    CanRedo: boolean,
    IsDirty: boolean
}

type TouchLayoutScreenData = {
    _backdropGui: ScreenGui,
    _backdropButton: TextButton,
    _chromeGui: ScreenGui,
    _canvas: TouchLayoutCanvas,
    _appBar: AppBar,
    _adjustmentPanel: ControlAdjustmentPanel,
    _exitButton: Button,
    _undoButton: Button,
    _redoButton: Button,
    _discardButton: Button,
    _presetsButton: Button,
    _saveButton: Button,
    ExitRequested: Signal,
    UndoRequested: Signal,
    RedoRequested: Signal,
    DiscardRequested: Signal,
    PresetsRequested: Signal,
    SaveRequested: Signal,
    BackgroundPressed: Signal,
    ScaleChanged: Signal,
    TransparencyChanged: Signal,
    AdjustmentStarted: Signal,
    AdjustmentEnded: Signal
}

export type TouchLayoutScreen = typeof(setmetatable({} :: TouchLayoutScreenData, TouchLayoutScreen))

-- Dimmed backdrop at the back, the ghost controls in the middle, and the app bar and sliders in front.
local BACKDROP_DISPLAY_ORDER = 100
local GHOST_DISPLAY_ORDER = 101
local CHROME_DISPLAY_ORDER = 102
local TOOLBAR_BUTTON_HEIGHT = 32
local PANEL_BOTTOM_INSET = 12

local function createLayer(parent: Instance, name: string, displayOrder: number): ScreenGui
    local layer = Instance.new("ScreenGui")
    layer.Name = name
    layer.ResetOnSpawn = false
    layer.DisplayOrder = displayOrder
    layer.Enabled = false
    layer.Parent = parent
    return layer
end

local function createBackdropButton(parent: Instance): TextButton
    local button = Instance.new("TextButton")
    button.Name = "Backdrop"
    button.Text = ""
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Selectable = false
    button.BackgroundColor3 = UITheme.Colors.Backdrop
    button.BackgroundTransparency = UITheme.BackdropTransparency
    button.Size = UDim2.fromScale(1, 1)
    button.Parent = parent
    return button
end

local function createToolbarButton(name: string, text: string, width: number): Button
    local buttonProps: Button.ButtonProps = {
        Name = name,
        Text = text,
        Size = UDim2.fromOffset(width, TOOLBAR_BUTTON_HEIGHT),
    }
    return Button.new(buttonProps)
end

local function createAppBar(): AppBar
    local appBarProps: AppBar.AppBarProps = {
        Name = "AppBar",
    }
    return AppBar.new(appBarProps)
end

local function createAdjustmentPanel(): ControlAdjustmentPanel
    local panelProps: ControlAdjustmentPanel.ControlAdjustmentPanelProps = {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -PANEL_BOTTOM_INSET),
    }
    return ControlAdjustmentPanel.new(panelProps)
end

local function forward(source: Signal, target: Signal): ()
    source:Connect(function(...)
        target:Fire(...)
    end)
end

function TouchLayoutScreen.new(parent: Instance, canvas: TouchLayoutCanvas): TouchLayoutScreen
    local self = setmetatable({}, TouchLayoutScreen)

    self._backdropGui = createLayer(parent, "TouchLayoutBackdrop", BACKDROP_DISPLAY_ORDER)
    self._backdropButton = createBackdropButton(self._backdropGui)
    self._chromeGui = createLayer(parent, "TouchLayoutChrome", CHROME_DISPLAY_ORDER)
    self._canvas = canvas
    self._appBar = createAppBar()
    self._adjustmentPanel = createAdjustmentPanel()
    self._exitButton = createToolbarButton("Exit", "Exit", 60)
    self._undoButton = createToolbarButton("Undo", "Undo", 60)
    self._redoButton = createToolbarButton("Redo", "Redo", 60)
    self._discardButton = createToolbarButton("ClearChanges", "Clear Changes", 112)
    self._presetsButton = createToolbarButton("Presets", "Presets", 80)
    self._saveButton = createToolbarButton("Save", "Save", 60)
    self.ExitRequested = Signal.new()
    self.UndoRequested = Signal.new()
    self.RedoRequested = Signal.new()
    self.DiscardRequested = Signal.new()
    self.PresetsRequested = Signal.new()
    self.SaveRequested = Signal.new()
    self.BackgroundPressed = Signal.new()
    self.ScaleChanged = Signal.new()
    self.TransparencyChanged = Signal.new()
    self.AdjustmentStarted = Signal.new()
    self.AdjustmentEnded = Signal.new()

    canvas:SetDisplayOrder(GHOST_DISPLAY_ORDER)
    self:_assembleChrome()
    self:_forwardEvents()
    self:SetEditState({ CanUndo = false, CanRedo = false, IsDirty = false })
    self._adjustmentPanel:ShowNothingSelected()

    return self :: TouchLayoutScreen
end

function TouchLayoutScreen.Render(self: TouchLayoutScreen, layout: TouchGamepadLayout): ()
    self._canvas:Render(layout)
end

-- Outlines the selected control and shows its size and opacity. Passing nil clears the selection.
function TouchLayoutScreen.SetSelection(self: TouchLayoutScreen, controlID: ControlID?, transform: ButtonTransform?): ()
    self._canvas:SetSelected(controlID)

    if controlID and transform then
        self._adjustmentPanel:ShowControl(controlID, transform.Scale, transform.Transparency)
    else
        self._adjustmentPanel:ShowNothingSelected()
    end
end

function TouchLayoutScreen.SetEditState(self: TouchLayoutScreen, editState: EditState): ()
    TouchLayoutScreen._setEnabled(self._undoButton, editState.CanUndo)
    TouchLayoutScreen._setEnabled(self._redoButton, editState.CanRedo)
    TouchLayoutScreen._setEnabled(self._discardButton, editState.IsDirty)
    TouchLayoutScreen._setEnabled(self._saveButton, editState.IsDirty)
end

function TouchLayoutScreen.SetVisible(self: TouchLayoutScreen, isVisible: boolean): ()
    self._backdropGui.Enabled = isVisible
    self._chromeGui.Enabled = isVisible
    self._canvas:SetVisible(isVisible)
end

function TouchLayoutScreen._setEnabled(button: Button, isEnabled: boolean): ()
    if isEnabled then
        button:Enable()
    else
        button:Disable()
    end
end

function TouchLayoutScreen._assembleChrome(self: TouchLayoutScreen): ()
    self._appBar:AddAction(self._exitButton:GetGuiObject())
    self._appBar:AddAction(self._undoButton:GetGuiObject())
    self._appBar:AddAction(self._redoButton:GetGuiObject())
    self._appBar:AddAction(self._discardButton:GetGuiObject())
    self._appBar:AddAction(self._presetsButton:GetGuiObject())
    self._appBar:AddAction(self._saveButton:GetGuiObject())

    self._appBar:GetGuiObject().Parent = self._chromeGui
    self._adjustmentPanel:GetGuiObject().Parent = self._chromeGui
end

function TouchLayoutScreen._forwardEvents(self: TouchLayoutScreen): ()
    forward(self._exitButton.Activated, self.ExitRequested)
    forward(self._undoButton.Activated, self.UndoRequested)
    forward(self._redoButton.Activated, self.RedoRequested)
    forward(self._discardButton.Activated, self.DiscardRequested)
    forward(self._presetsButton.Activated, self.PresetsRequested)
    forward(self._saveButton.Activated, self.SaveRequested)
    forward(self._adjustmentPanel.ScaleChanged, self.ScaleChanged)
    forward(self._adjustmentPanel.TransparencyChanged, self.TransparencyChanged)
    forward(self._adjustmentPanel.AdjustmentStarted, self.AdjustmentStarted)
    forward(self._adjustmentPanel.AdjustmentEnded, self.AdjustmentEnded)

    self._backdropButton.Activated:Connect(function()
        self:_handleBackdropActivated()
    end)
end

function TouchLayoutScreen._handleBackdropActivated(self: TouchLayoutScreen): ()
    self.BackgroundPressed:Fire()
end

function TouchLayoutScreen._destroyButtons(self: TouchLayoutScreen): ()
    self._exitButton:Destroy()
    self._undoButton:Destroy()
    self._redoButton:Destroy()
    self._discardButton:Destroy()
    self._presetsButton:Destroy()
    self._saveButton:Destroy()
end

function TouchLayoutScreen._disconnectSignals(self: TouchLayoutScreen): ()
    self.ExitRequested:DisconnectAll()
    self.UndoRequested:DisconnectAll()
    self.RedoRequested:DisconnectAll()
    self.DiscardRequested:DisconnectAll()
    self.PresetsRequested:DisconnectAll()
    self.SaveRequested:DisconnectAll()
    self.BackgroundPressed:DisconnectAll()
    self.ScaleChanged:DisconnectAll()
    self.TransparencyChanged:DisconnectAll()
    self.AdjustmentStarted:DisconnectAll()
    self.AdjustmentEnded:DisconnectAll()
end

-- The canvas was handed in, so whoever made it destroys it.
function TouchLayoutScreen.Destroy(self: TouchLayoutScreen): ()
    self:_disconnectSignals()
    self._adjustmentPanel:Destroy()
    self:_destroyButtons()
    self._appBar:Destroy()
    self._chromeGui:Destroy()
    self._backdropGui:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchLayoutScreen)
return TouchLayoutScreen
