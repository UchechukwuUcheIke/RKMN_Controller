--!strict
local ControlCustomizationUI = {}
ControlCustomizationUI.__index = ControlCustomizationUI

local PlayerInputFolder = game:GetService("ReplicatedStorage").PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputDevice = require(PlayerInputFolder.InputDevice)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)
local ControlProfile = require(PlayerInputFolder.ControlProfile)
local DeviceDetector = require(PlayerInputFolder.DeviceDetector)
local PlayerInputFacade = require(PlayerInputFolder.PlayerInputFacade)
local BindingCapture = require(PlayerInputFolder.BindingCapture)
local ControlCustomizationView = require(script.Parent.ControlCustomizationView)
local BindingsScreen = require(script.Parent.BindingsScreen)

type ActionID = InputAction.ActionID
type InputDevice = InputDevice.InputDevice
type InputBinding = InputSchemeTypes.InputBinding
type ControlProfile = ControlProfile.ControlProfile
type DeviceDetector = DeviceDetector.DeviceDetector
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type BindingCapture = BindingCapture.BindingCapture
type ControlCustomizationView = ControlCustomizationView.ControlCustomizationView
type BindingsScreen = BindingsScreen.BindingsScreen
type Connection = { Disconnect: (self: any) -> () }
-- Runs the callback on a later frame, so it lands after the input event that triggered it has been seen by everyone.
type NextFrameScheduler = (callback: () -> ()) -> ()

type ControlCustomizationUIData = {
    _deviceDetector: DeviceDetector,
    _controlProfile: ControlProfile,
    _playerInput: PlayerInputFacade,
    _bindingCapture: BindingCapture,
    _view: ControlCustomizationView,
    _bindingsScreen: BindingsScreen,
    _runNextFrame: NextFrameScheduler,

    _isOpen: boolean,
    _connections: {Connection}
}

export type ControlCustomizationUI = typeof(setmetatable({} :: ControlCustomizationUIData, ControlCustomizationUI))

-- Escape works on every device, but a gamepad-only player has to be told about Select instead.
local CANCEL_KEY_NAMES: {[InputDevice]: string} = {
    [InputDevice.Keyboard] = "Escape",
    [InputDevice.Gamepad] = "Select",
}

function ControlCustomizationUI.new(
    deviceDetector: DeviceDetector,
    controlProfile: ControlProfile,
    playerInput: PlayerInputFacade,
    bindingCapture: BindingCapture,
    view: ControlCustomizationView,
    runNextFrame: NextFrameScheduler
): ControlCustomizationUI
    local self = setmetatable({}, ControlCustomizationUI)

    self._deviceDetector = deviceDetector
    self._controlProfile = controlProfile
    self._playerInput = playerInput
    self._bindingCapture = bindingCapture
    self._view = view
    self._bindingsScreen = view:GetBindingsScreen()
    self._runNextFrame = runNextFrame

    self._isOpen = false
    self._connections = {}

    return self :: ControlCustomizationUI
end

function ControlCustomizationUI.Enable(self: ControlCustomizationUI): ()
    if #self._connections > 0 then
        return
    end

    table.insert(self._connections, self._playerInput.OnMenuPressed:Connect(function()
        self:_toggle()
    end))
    table.insert(self._connections, self._deviceDetector.OnContextChanged:Connect(function()
        self:_handleDeviceChanged()
    end))
    table.insert(self._connections, self._controlProfile.SchemeChanged:Connect(function(editedDevice: InputDevice)
        self:_handleSchemeChanged(editedDevice)
    end))
    table.insert(self._connections, self._bindingsScreen.OnRebindRequested:Connect(function(actionName: ActionID)
        self:_beginRebind(actionName)
    end))
    table.insert(self._connections, self._bindingsScreen.OnResetRequested:Connect(function()
        self:_resetCurrentDevice()
    end))
end

function ControlCustomizationUI.Disable(self: ControlCustomizationUI): ()
    self:Close()

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function ControlCustomizationUI.IsOpen(self: ControlCustomizationUI): boolean
    return self._isOpen
end

function ControlCustomizationUI.Open(self: ControlCustomizationUI): ()
    if self._isOpen then
        return
    end

    self._isOpen = true
    self._playerInput:SuspendGameplayInput()
    self._view:SetVisible(true)
    self:_refresh()
end

function ControlCustomizationUI.Close(self: ControlCustomizationUI): ()
    if not self._isOpen then
        return
    end

    self._isOpen = false
    self._bindingCapture:Cancel()
    self._view:SetVisible(false)
    self._playerInput:ResumeGameplayInput()
end

function ControlCustomizationUI._toggle(self: ControlCustomizationUI): ()
    if self._isOpen then
        self:Close()
    else
        self:Open()
    end
end

function ControlCustomizationUI._refresh(self: ControlCustomizationUI): ()
    local device = self._deviceDetector:GetCurrentDevice()
    if device == InputDevice.Touch then
        self._bindingsScreen:SetVisible(false)
        return
    end

    self._bindingsScreen:SetVisible(true)
    self._bindingsScreen:Render(device, self._controlProfile:GetScheme(device))
end

function ControlCustomizationUI._handleSchemeChanged(self: ControlCustomizationUI, editedDevice: InputDevice): ()
    if self._isOpen and editedDevice == self._deviceDetector:GetCurrentDevice() then
        self:_refresh()
    end
end

function ControlCustomizationUI._handleDeviceChanged(self: ControlCustomizationUI): ()
    self._bindingCapture:Cancel()

    if self._isOpen then
        self:_refresh()
    end
end

function ControlCustomizationUI._beginRebind(self: ControlCustomizationUI, actionName: ActionID): ()
    local device = self._deviceDetector:GetCurrentDevice()
    if device == InputDevice.Touch then
        return
    end

    -- The menu key is a bindable key like any other, so it must not close the menu while the player is choosing one.
    self._playerInput:DisableMenuKey()
    self._bindingCapture:Begin(device, function(binding: InputBinding?)
        self:_finishRebind(device, actionName, binding)
    end)
    self._bindingsScreen:SetCapturing(actionName, CANCEL_KEY_NAMES[device])
end

function ControlCustomizationUI._finishRebind(self: ControlCustomizationUI, device: InputDevice, actionName: ActionID, binding: InputBinding?): ()
    if binding then
        self._controlProfile:BindKey(device, actionName, binding)
    end

    self._bindingsScreen:SetCapturing(nil)
    self:_enableMenuKeyNextFrame()
end

function ControlCustomizationUI._enableMenuKeyNextFrame(self: ControlCustomizationUI): ()
    self._runNextFrame(function()
        if not self._bindingCapture:IsCapturing() then
            self._playerInput:EnableMenuKey()
        end
    end)
end

function ControlCustomizationUI._resetCurrentDevice(self: ControlCustomizationUI): ()
    local device = self._deviceDetector:GetCurrentDevice()
    if device ~= InputDevice.Touch then
        self._controlProfile:ResetDevice(device)
    end
end

function ControlCustomizationUI.Destroy(self: ControlCustomizationUI): ()
    self:Disable()
    self._view:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ControlCustomizationUI)
return ControlCustomizationUI
