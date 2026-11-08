--!strict
local TouchLayoutEditor = {}
TouchLayoutEditor.__index = TouchLayoutEditor

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputDevice = require(PlayerInputFolder.InputDevice)
local DeviceDetector = require(PlayerInputFolder.DeviceDetector)
local PlayerInputFacade = require(PlayerInputFolder.PlayerInputFacade)
local TouchGamepadFolder = ReplicatedStorage.TouchGamepad
local TouchGamepadLayoutRegistry = require(TouchGamepadFolder.TouchGamepadLayoutRegistry)
local TouchGamepadPresenter = require(TouchGamepadFolder.TouchGamepadPresenter)
local TouchLayoutPresets = require(TouchGamepadFolder.TouchLayoutPresets)
local TouchLayoutProfile = require(TouchGamepadFolder.TouchLayoutProfile)
local TouchLayoutEditSession = require(script.Parent.TouchLayoutEditSession)
local UIComponents = script.Parent.UIComponents
local TouchLayoutCanvas = require(UIComponents.TouchLayoutCanvas)
local TouchLayoutScreen = require(UIComponents.TouchLayoutScreen)
local UnsavedChangesChoice = require(UIComponents.UnsavedChangesChoice)

type InputDevice = InputDevice.InputDevice
type DeviceDetector = DeviceDetector.DeviceDetector
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type ControlID = TouchGamepadLayoutRegistry.ControlID
type TouchGamepadPresenter = TouchGamepadPresenter.TouchGamepadPresenter
type LayoutPreset = TouchLayoutPresets.LayoutPreset
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout
type TouchLayoutProfile = TouchLayoutProfile.TouchLayoutProfile
type TouchLayoutEditSession = TouchLayoutEditSession.TouchLayoutEditSession
type TouchLayoutCanvas = TouchLayoutCanvas.TouchLayoutCanvas
type TouchLayoutScreen = TouchLayoutScreen.TouchLayoutScreen
type UnsavedChangesChoice = UnsavedChangesChoice.UnsavedChangesChoice
type Connection = { Disconnect: (self: any) -> () }

-- Dragging a control and pulling a slider both edit the layout, and the session has room for one gesture at a time.
type GestureOwner = "Canvas" | "Sliders"

export type TouchLayoutEditorDependencies = {
    DeviceDetector: DeviceDetector,
    LayoutProfile: TouchLayoutProfile,
    PlayerInput: PlayerInputFacade,
    TouchGamepad: TouchGamepadPresenter,
    Canvas: TouchLayoutCanvas,
    Screen: TouchLayoutScreen,
    Presets: {LayoutPreset},
    FixedControls: {ControlID}
}

type TouchLayoutEditorData = {
    _deviceDetector: DeviceDetector,
    _layoutProfile: TouchLayoutProfile,
    _playerInput: PlayerInputFacade,
    _touchGamepad: TouchGamepadPresenter,
    _canvas: TouchLayoutCanvas,
    _screen: TouchLayoutScreen,
    _presets: {LayoutPreset},
    _fixedControls: {ControlID},

    _session: TouchLayoutEditSession?,
    _sessionConnection: Connection?,
    _gestureOwner: GestureOwner?,
    _connections: {Connection}
}

export type TouchLayoutEditor = typeof(setmetatable({} :: TouchLayoutEditorData, TouchLayoutEditor))

function TouchLayoutEditor.new(dependencies: TouchLayoutEditorDependencies): TouchLayoutEditor
    local self = setmetatable({}, TouchLayoutEditor)

    self._deviceDetector = dependencies.DeviceDetector
    self._layoutProfile = dependencies.LayoutProfile
    self._playerInput = dependencies.PlayerInput
    self._touchGamepad = dependencies.TouchGamepad
    self._canvas = dependencies.Canvas
    self._screen = dependencies.Screen
    self._presets = dependencies.Presets
    self._fixedControls = dependencies.FixedControls

    self._session = nil
    self._sessionConnection = nil
    self._gestureOwner = nil
    self._connections = {}

    return self :: TouchLayoutEditor
end

function TouchLayoutEditor.Enable(self: TouchLayoutEditor): ()
    if #self._connections > 0 then
        return
    end

    self:_subscribeToGame()
    self:_subscribeToCanvas()
    self:_subscribeToScreen()
end

function TouchLayoutEditor.Disable(self: TouchLayoutEditor): ()
    self:Close()

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function TouchLayoutEditor.IsOpen(self: TouchLayoutEditor): boolean
    return self._session ~= nil
end

function TouchLayoutEditor.Open(self: TouchLayoutEditor): ()
    if self:IsOpen() or self._deviceDetector:GetCurrentDevice() ~= InputDevice.Touch then
        return
    end

    local session = TouchLayoutEditSession.new(self._layoutProfile:GetLayout())
    self._session = session
    self._sessionConnection = session.Changed:Connect(function()
        self:_refresh()
    end)

    self._touchGamepad:Suspend()
    self._playerInput:SuspendGameplayInput()
    self._screen:SetVisible(true)
    self:_refresh()
end

-- Anything not saved is dropped. Exit asks first; this is for when the editor has to go regardless.
function TouchLayoutEditor.Close(self: TouchLayoutEditor): ()
    local session = self._session
    if not session then
        return
    end

    self:_endGesture()
    self:_disconnectSession()
    session:Destroy()
    self._session = nil

    self._screen:HideUnsavedChangesPrompt()
    self._screen:SetSelection(nil, nil)
    self._screen:SetVisible(false)
    self._touchGamepad:Resume()
    self._playerInput:ResumeGameplayInput()
end

function TouchLayoutEditor._subscribeToGame(self: TouchLayoutEditor): ()
    table.insert(self._connections, self._playerInput.OnMenuPressed:Connect(function()
        self:_handleMenuPressed()
    end))
    table.insert(self._connections, self._deviceDetector.OnContextChanged:Connect(function(newDevice: InputDevice)
        self:_handleDeviceChanged(newDevice)
    end))
end

function TouchLayoutEditor._subscribeToCanvas(self: TouchLayoutEditor): ()
    local canvas = self._canvas

    table.insert(self._connections, canvas.ControlPressed:Connect(function(controlID: ControlID)
        self:_handleControlPressed(controlID)
    end))
    table.insert(self._connections, canvas.ControlDragged:Connect(function(controlID: ControlID, position: UDim2)
        self:_handleControlDragged(controlID, position)
    end))
    table.insert(self._connections, canvas.PointerReleased:Connect(function()
        self:_handlePointerReleased()
    end))
end

function TouchLayoutEditor._subscribeToScreen(self: TouchLayoutEditor): ()
    local screen = self._screen

    table.insert(self._connections, screen.ScaleChanged:Connect(function(scale: number)
        self:_handleScaleChanged(scale)
    end))
    table.insert(self._connections, screen.TransparencyChanged:Connect(function(transparency: number)
        self:_handleTransparencyChanged(transparency)
    end))
    table.insert(self._connections, screen.AdjustmentStarted:Connect(function()
        self:_beginGesture("Sliders")
    end))
    table.insert(self._connections, screen.AdjustmentEnded:Connect(function()
        self:_endGestureOwnedBy("Sliders")
    end))
    table.insert(self._connections, screen.BackgroundPressed:Connect(function()
        self:_handleBackgroundPressed()
    end))
    table.insert(self._connections, screen.UndoRequested:Connect(function()
        self:_handleUndoRequested()
    end))
    table.insert(self._connections, screen.RedoRequested:Connect(function()
        self:_handleRedoRequested()
    end))
    table.insert(self._connections, screen.DiscardRequested:Connect(function()
        self:_handleDiscardRequested()
    end))
    table.insert(self._connections, screen.SaveRequested:Connect(function()
        self:_save()
    end))
    table.insert(self._connections, screen.ExitRequested:Connect(function()
        self:_handleExitRequested()
    end))
    table.insert(self._connections, screen.PresetChosen:Connect(function(presetID: string)
        self:_handlePresetChosen(presetID)
    end))
    table.insert(self._connections, screen.UnsavedChoiceMade:Connect(function(choice: UnsavedChangesChoice)
        self:_handleUnsavedChoice(choice)
    end))
end

-- The menu button only opens the editor; the editor's own Exit button is the way out.
function TouchLayoutEditor._handleMenuPressed(self: TouchLayoutEditor): ()
    self:Open()
end

function TouchLayoutEditor._handleDeviceChanged(self: TouchLayoutEditor, newDevice: InputDevice): ()
    if newDevice ~= InputDevice.Touch then
        self:Close()
    end
end

function TouchLayoutEditor._handleControlPressed(self: TouchLayoutEditor, controlID: ControlID): ()
    local session = self._session
    if not session or self._gestureOwner then
        return
    end

    session:SelectControl(controlID)
    self:_beginGesture("Canvas")
end

function TouchLayoutEditor._handleControlDragged(self: TouchLayoutEditor, controlID: ControlID, position: UDim2): ()
    local session = self._session
    if session and self._gestureOwner == "Canvas" then
        session:SetControlPosition(controlID, position)
    end
end

function TouchLayoutEditor._handlePointerReleased(self: TouchLayoutEditor): ()
    self:_endGestureOwnedBy("Canvas")
end

function TouchLayoutEditor._handleScaleChanged(self: TouchLayoutEditor, scale: number): ()
    local session = self._session
    local selected = if session then session:GetSelectedControl() else nil
    if session and selected and self._gestureOwner == "Sliders" then
        session:SetControlScale(selected, scale)
    end
end

function TouchLayoutEditor._handleTransparencyChanged(self: TouchLayoutEditor, transparency: number): ()
    local session = self._session
    local selected = if session then session:GetSelectedControl() else nil
    if session and selected and self._gestureOwner == "Sliders" then
        session:SetControlTransparency(selected, transparency)
    end
end

function TouchLayoutEditor._handleBackgroundPressed(self: TouchLayoutEditor): ()
    local session = self._session
    if session and not self._gestureOwner then
        session:SelectControl(nil)
    end
end

function TouchLayoutEditor._handleUndoRequested(self: TouchLayoutEditor): ()
    if self._session then
        self._session:Undo()
    end
end

function TouchLayoutEditor._handleRedoRequested(self: TouchLayoutEditor): ()
    if self._session then
        self._session:Redo()
    end
end

function TouchLayoutEditor._handleDiscardRequested(self: TouchLayoutEditor): ()
    if self._session then
        self._session:DiscardChanges()
    end
end

function TouchLayoutEditor._handleExitRequested(self: TouchLayoutEditor): ()
    local session = self._session
    if not session then
        return
    end

    if session:IsDirty() then
        self._screen:ShowUnsavedChangesPrompt()
    else
        self:Close()
    end
end

-- A preset places every control, but the controls the player cannot move stay where they are.
function TouchLayoutEditor._handlePresetChosen(self: TouchLayoutEditor, presetID: string): ()
    local session = self._session
    local preset = self:_findPreset(presetID)
    if not session or not preset then
        return
    end

    session:ReplaceLayout(self:_keepFixedControls(preset.Layout, session:GetLayout()))
end

function TouchLayoutEditor._findPreset(self: TouchLayoutEditor, presetID: string): LayoutPreset?
    for _, preset in ipairs(self._presets) do
        if preset.Id == presetID then
            return preset
        end
    end
    return nil
end

function TouchLayoutEditor._keepFixedControls(self: TouchLayoutEditor, presetLayout: TouchGamepadLayout, currentLayout: TouchGamepadLayout): TouchGamepadLayout
    local layout = presetLayout
    for _, controlID in ipairs(self._fixedControls) do
        local current = currentLayout:GetTransform(controlID)
        if current and layout:HasControl(controlID) then
            layout = layout:CopyWithTransform(controlID, current)
        end
    end
    return layout
end

function TouchLayoutEditor._handleUnsavedChoice(self: TouchLayoutEditor, choice: UnsavedChangesChoice): ()
    if not self._session then
        return
    end

    if choice == UnsavedChangesChoice.Save then
        self:_save()
        self:Close()
    elseif choice == UnsavedChangesChoice.Discard then
        self:Close()
    else
        self._screen:HideUnsavedChangesPrompt()
    end
end

function TouchLayoutEditor._save(self: TouchLayoutEditor): ()
    local session = self._session
    if not session then
        return
    end

    self._layoutProfile:SetLayout(session:GetLayout())
    session:MarkSaved()
end

function TouchLayoutEditor._beginGesture(self: TouchLayoutEditor, owner: GestureOwner): ()
    local session = self._session
    if not session or self._gestureOwner then
        return
    end

    session:BeginGesture()
    self._gestureOwner = owner
end

function TouchLayoutEditor._endGestureOwnedBy(self: TouchLayoutEditor, owner: GestureOwner): ()
    if self._gestureOwner == owner then
        self:_endGesture()
    end
end

function TouchLayoutEditor._endGesture(self: TouchLayoutEditor): ()
    local session = self._session
    if session and self._gestureOwner then
        session:EndGesture()
    end
    self._gestureOwner = nil
end

function TouchLayoutEditor._refresh(self: TouchLayoutEditor): ()
    local session = self._session
    if not session then
        return
    end

    local layout = session:GetLayout()
    local selected = session:GetSelectedControl()
    local selectedTransform = if selected then layout:GetTransform(selected) else nil

    self._screen:Render(layout)
    self._screen:SetSelection(selected, selectedTransform)
    self._screen:SetEditState({
        CanUndo = session:CanUndo(),
        CanRedo = session:CanRedo(),
        IsDirty = session:IsDirty(),
    })
end

function TouchLayoutEditor._disconnectSession(self: TouchLayoutEditor): ()
    if self._sessionConnection then
        self._sessionConnection:Disconnect()
        self._sessionConnection = nil
    end
end

function TouchLayoutEditor.Destroy(self: TouchLayoutEditor): ()
    self:Disable()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchLayoutEditor)
return TouchLayoutEditor
