--!strict
local TouchGamepadPresenter = {}
TouchGamepadPresenter.__index = TouchGamepadPresenter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputDevice = require(PlayerInputFolder.InputDevice)
local DeviceDetector = require(PlayerInputFolder.DeviceDetector)
local PlayerInputFacade = require(PlayerInputFolder.PlayerInputFacade)
local TouchGamepadUI = require(script.Parent.UserInterface.TouchGamepadUI)
local MobileButtonPositioner = require(script.Parent.MobileButtonPositioner)
local TouchLayoutProfile = require(script.Parent.TouchLayoutProfile)

type InputDevice = InputDevice.InputDevice
type DeviceDetector = DeviceDetector.DeviceDetector
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type TouchGamepadUI = TouchGamepadUI.TouchGamepadUI
type MobileButtonPositioner = MobileButtonPositioner.MobileButtonPositioner
type TouchLayoutProfile = TouchLayoutProfile.TouchLayoutProfile
type Connection = { Disconnect: (self: any) -> () }

type TouchGamepadPresenterData = {
    _deviceDetector: DeviceDetector,
    _playerInput: PlayerInputFacade,
    _gamepadUI: TouchGamepadUI,
    _positioner: MobileButtonPositioner,
    _layoutProfile: TouchLayoutProfile,

    _hasBoundButtons: boolean,
    _contextConnection: Connection?,
    _layoutConnection: Connection?
}

export type TouchGamepadPresenter = typeof(setmetatable({} :: TouchGamepadPresenterData, TouchGamepadPresenter))

function TouchGamepadPresenter.new(
    deviceDetector: DeviceDetector,
    playerInput: PlayerInputFacade,
    gamepadUI: TouchGamepadUI,
    positioner: MobileButtonPositioner,
    layoutProfile: TouchLayoutProfile
): TouchGamepadPresenter
    local self = setmetatable({}, TouchGamepadPresenter)

    self._deviceDetector = deviceDetector
    self._playerInput = playerInput
    self._gamepadUI = gamepadUI
    self._positioner = positioner
    self._layoutProfile = layoutProfile

    self._hasBoundButtons = false
    self._contextConnection = nil
    self._layoutConnection = nil

    return self :: TouchGamepadPresenter
end

function TouchGamepadPresenter.Enable(self: TouchGamepadPresenter): ()
    if self._contextConnection then
        return
    end

    GuiService.TouchControlsEnabled = false

    self._contextConnection = self._deviceDetector.OnContextChanged:Connect(function(newDevice: InputDevice)
        self:_handleContextChange(newDevice)
    end)

    self._layoutConnection = self._layoutProfile.LayoutChanged:Connect(function()
        self:_handleLayoutChange()
    end)

    self:_handleContextChange(self._deviceDetector:GetCurrentDevice())
end

function TouchGamepadPresenter.Disable(self: TouchGamepadPresenter): ()
    GuiService.TouchControlsEnabled = true

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

function TouchGamepadPresenter._handleLayoutChange(self: TouchGamepadPresenter): ()
    if self._hasBoundButtons then
        local layout = self._layoutProfile:GetLayout()
        self._positioner:ApplyLayout(layout)
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

        self._playerInput:BindVirtualButton(actionName, button:GetInstance())
    end

    for controlID, control in pairs(self._gamepadUI:GetPositionableControls()) do
        self._positioner:RegisterControl(controlID, control)
    end

    self._positioner:ApplyLayout(self._layoutProfile:GetLayout())
end

function TouchGamepadPresenter._unbindConnection(self: TouchGamepadPresenter): ()
    if self._contextConnection then
        self._contextConnection:Disconnect()
        self._contextConnection = nil
    end
    if self._layoutConnection then
        self._layoutConnection:Disconnect()
        self._layoutConnection = nil
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
