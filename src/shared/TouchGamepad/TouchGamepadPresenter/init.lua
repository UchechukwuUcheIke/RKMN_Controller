--!strict
local TouchGamepadPresenter = {}
TouchGamepadPresenter.__index = TouchGamepadPresenter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputDevice = require(PlayerInputFolder.InputDevice)
local DeviceDetector = require(PlayerInputFolder.DeviceDetector)
local PlayerInputFacade = require(PlayerInputFolder.PlayerInputFacade)
local TouchGamepadUI = require(script.Parent.UserInterface.TouchGamepadUI)
local MobileButtonPositioner = require(script.Parent.MobileButtonPositioner)
local TouchGamepadLayoutRegistry = require(script.Parent.TouchGamepadLayoutRegistry)

type InputDevice = InputDevice.InputDevice
type DeviceDetector = DeviceDetector.DeviceDetector
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type TouchGamepadUI = TouchGamepadUI.TouchGamepadUI
type MobileButtonPositioner = MobileButtonPositioner.MobileButtonPositioner
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout
type Connection = { Disconnect: (self: any) -> () }

type TouchGamepadPresenterData = {
    _deviceDetector: DeviceDetector,
    _playerInput: PlayerInputFacade,
    _gamepadUI: TouchGamepadUI,
    _positioner: MobileButtonPositioner,
    _layout: TouchGamepadLayout,

    _hasBoundButtons: boolean,
    _contextConnection: Connection?
}

export type TouchGamepadPresenter = typeof(setmetatable({} :: TouchGamepadPresenterData, TouchGamepadPresenter))

function TouchGamepadPresenter.new(
    deviceDetector: DeviceDetector,
    playerInput: PlayerInputFacade,
    gamepadUI: TouchGamepadUI,
    positioner: MobileButtonPositioner,
    layout: TouchGamepadLayout
): TouchGamepadPresenter
    local self = setmetatable({}, TouchGamepadPresenter)

    self._deviceDetector = deviceDetector
    self._playerInput = playerInput
    self._gamepadUI = gamepadUI
    self._positioner = positioner
    self._layout = layout

    self._hasBoundButtons = false
    self._contextConnection = nil

    return self :: TouchGamepadPresenter
end

function TouchGamepadPresenter.Enable(self: TouchGamepadPresenter): ()
    if self._contextConnection then
        return
    end

    self._contextConnection = self._deviceDetector.OnContextChanged:Connect(function(newDevice: InputDevice)
        self:_handleContextChange(newDevice)
    end)

    self:_handleContextChange(self._deviceDetector:GetCurrentDevice())
end

function TouchGamepadPresenter.Disable(self: TouchGamepadPresenter): ()
    self:_unbindConnection()
    self:_hide()
end

function TouchGamepadPresenter._handleContextChange(self: TouchGamepadPresenter, newDevice: InputDevice): ()
    if newDevice == InputDevice.Touch then
        self:_initializeButtons()
        self._gamepadUI:SetVisible(true)
    else
        self:_hide()
    end
end

function TouchGamepadPresenter._hide(self: TouchGamepadPresenter): ()
    self._gamepadUI:SetVisible(false)
    self._playerInput:ReleaseVirtualHolds()
end

function TouchGamepadPresenter._initializeButtons(self: TouchGamepadPresenter): ()
    if self._hasBoundButtons then
        return
    end
    self._hasBoundButtons = true

    for _, actionName in pairs(InputAction) do
        local button = self._gamepadUI:GetButton(actionName)

        self._positioner:RegisterButton(actionName, button)
        self._playerInput:BindVirtualButton(actionName, button:GetInstance())
    end

    self._positioner:ApplyLayout(self._layout)
end

function TouchGamepadPresenter._unbindConnection(self: TouchGamepadPresenter): ()
    if self._contextConnection then
        self._contextConnection:Disconnect()
        self._contextConnection = nil
    end
end

function TouchGamepadPresenter.Destroy(self: TouchGamepadPresenter): ()
    self:Disable()
    self._positioner:Destroy()
    self._gamepadUI:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchGamepadPresenter)
return TouchGamepadPresenter
