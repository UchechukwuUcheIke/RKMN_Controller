--!strict
local DeviceDetector = {}
DeviceDetector.__index = DeviceDetector

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevPackages = ReplicatedStorage.DevPackages
local Signal = require(DevPackages.goodsignal)

local ControlProfile = require(script.Parent.ControlProfile)
local InputMapper = require(script.Parent.InputMapper)
local InputDevice = require(ReplicatedStorage.Data.InputDevice)

type Signal = typeof(Signal)
type ControlProfile = ControlProfile.ControlProfile
type InputMapper = InputMapper.InputMapper
type InputDevice = InputDevice.InputDevice

type DeviceDetectorData = {
    _mapper: InputMapper,
    _controlProfile: ControlProfile,
    _currentDevice: InputDevice,
    _connections: {RBXScriptConnection},
    _userInputService: UserInputService,
    OnContextChanged: Signal
}

export type DeviceDetector = typeof(setmetatable({} :: DeviceDetectorData, DeviceDetector))

local DEVICE_BY_PREFERRED_INPUT: {[Enum.PreferredInput]: InputDevice} = {
    [Enum.PreferredInput.KeyboardAndMouse] = InputDevice.Keyboard,
    [Enum.PreferredInput.Gamepad] = InputDevice.Gamepad,
    [Enum.PreferredInput.Touch] = InputDevice.Touch,
}

function DeviceDetector.new(userInputService: UserInputService, mapper: InputMapper, controlProfile: ControlProfile): DeviceDetector
    local self = setmetatable({}, DeviceDetector)

    self._mapper = mapper
    self._controlProfile = controlProfile
    self._connections = {}
    self._userInputService = userInputService
    self.OnContextChanged = Signal.new()

    self._currentDevice = self:_resolveDevice()
    self:_applySchemeForDevice()
    self:_bindEvents()

    return self :: DeviceDetector
end

function DeviceDetector._resolveDevice(self: DeviceDetector): InputDevice
    return DEVICE_BY_PREFERRED_INPUT[self._userInputService.PreferredInput]
end

function DeviceDetector._applySchemeForDevice(self: DeviceDetector): ()
    self._mapper:LoadControlScheme(self._controlProfile:GetScheme(self._currentDevice))
end

function DeviceDetector._handlePreferredInputChanged(self: DeviceDetector): ()
    local newDevice: InputDevice = self:_resolveDevice()

    if newDevice ~= self._currentDevice then
        self._currentDevice = newDevice
        self:_applySchemeForDevice()
        self.OnContextChanged:Fire(newDevice)
    end
end

function DeviceDetector._bindEvents(self: DeviceDetector): ()
    local connection = self._userInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function(...)
        self:_handlePreferredInputChanged()
    end)
    
    table.insert(self._connections, connection)

    local profileConnection = self._controlProfile.SchemeChanged:Connect(function(editedDevice: InputDevice)
        if editedDevice == self._currentDevice then
            self:_applySchemeForDevice()
        end
    end)
    table.insert(self._connections, profileConnection)
end

function DeviceDetector.GetCurrentDevice(self: DeviceDetector): InputDevice
    return self._currentDevice
end

function DeviceDetector._unbindEvents(self: DeviceDetector): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function DeviceDetector.Destroy(self: DeviceDetector): ()
    self:_unbindEvents()
    self.OnContextChanged:DisconnectAll()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(DeviceDetector)
return DeviceDetector
