--!strict
local DeviceDetector = {}
DeviceDetector.__index = DeviceDetector

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevPackages = ReplicatedStorage.DevPackages
local Signal = require(DevPackages.goodsignal)

local KeyboardSchemes = require(script.Parent.KeyboardSchemes)
local GamepadSchemes = require(script.Parent.GamepadSchemes)
local InputMapper = require(script.Parent.InputMapper)
local InputDevice = require(script.Parent.InputDevice)

type Signal = typeof(Signal)
type InputMapper = InputMapper.InputMapper
type InputDevice = InputDevice.InputDevice
type Connection = { Disconnect: (self: any) -> () }

type DeviceDetectorData = {
    _mapper: InputMapper,
    _currentDevice: InputDevice,
    _connections: {Connection},
    _userInputService: UserInputService,
    OnContextChanged: Signal
}

export type DeviceDetector = typeof(setmetatable({} :: DeviceDetectorData, DeviceDetector))

function DeviceDetector.new(userInputService: UserInputService, mapper: InputMapper): DeviceDetector
    local self = setmetatable({}, DeviceDetector)

    self._mapper = mapper
    self._connections = {}
    self._userInputService = userInputService
    self.OnContextChanged = Signal.new()

    self._currentDevice = self:_resolveDevice()
    self:_applySchemeForDevice()
    self:_bindEvents()

    return self :: DeviceDetector
end

function DeviceDetector._resolveDevice(self: DeviceDetector): InputDevice
    local inputType = self._userInputService:GetLastInputType()

    local isKeyboard = inputType == Enum.UserInputType.Keyboard
    if isKeyboard then
        return InputDevice.Keyboard
    end

    local isTouchScreen = inputType == Enum.UserInputType.Touch
    if isTouchScreen then
        return InputDevice.Touch
    end

    local isGamepad = inputType.Name:match("Gamepad")
    if isGamepad then
        return InputDevice.Gamepad
    end

    return InputDevice.Keyboard
end

function DeviceDetector._applySchemeForDevice(self: DeviceDetector): ()
    local device = self._currentDevice
    if device == InputDevice.Keyboard then
        self._mapper:LoadControlScheme(KeyboardSchemes.Standard)
    elseif device == InputDevice.Gamepad then
        self._mapper:LoadControlScheme(GamepadSchemes.Standard)
    elseif device == InputDevice.Touch then
        self._mapper:LoadControlScheme({})
    end
end

function DeviceDetector._bindEvents(self: DeviceDetector): ()
    local function handleInputTypeChanged(_lastInputType)
        local newDevice = self:_resolveDevice()

        if newDevice ~= self._currentDevice then
            self._currentDevice = newDevice
            self:_applySchemeForDevice()
            self.OnContextChanged:Fire(newDevice)
        end
    end

    local connection = self._userInputService.LastInputTypeChanged:Connect(handleInputTypeChanged)
    table.insert(self._connections, connection)
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
