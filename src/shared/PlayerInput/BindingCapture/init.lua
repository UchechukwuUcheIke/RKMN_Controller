--!strict
local BindingCapture = {}
BindingCapture.__index = BindingCapture

local PlayerInputFolder = script.Parent
local InputDevice = require(PlayerInputFolder.InputDevice)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)

type InputDevice = InputDevice.InputDevice
type InputBinding = InputSchemeTypes.InputBinding
type Connection = { Disconnect: (self: any) -> () }
-- Called once per capture: with the pressed binding, or nil when the capture was cancelled.
type CaptureCallback = (InputBinding?) -> ()

type BindingCaptureData = {
    _userInputService: UserInputService,
    _connection: Connection?,
    _onCaptured: CaptureCallback?
}

export type BindingCapture = typeof(setmetatable({} :: BindingCaptureData, BindingCapture))

local MOUSE_BUTTONS: {[Enum.UserInputType]: boolean} = {
    [Enum.UserInputType.MouseButton1] = true,
    [Enum.UserInputType.MouseButton2] = true,
    [Enum.UserInputType.MouseButton3] = true,
}

-- Sticks report movement rather than presses, so they are not something a player can "press" to bind.
local STICK_KEYS: {[Enum.KeyCode]: boolean} = {
    [Enum.KeyCode.Thumbstick1] = true,
    [Enum.KeyCode.Thumbstick2] = true,
}

local function isGamepadInput(inputType: Enum.UserInputType): boolean
    return string.find(inputType.Name, "Gamepad") ~= nil
end

-- Turns a press into a binding for the device being edited, or nil when that device has no use for it.
local function toBinding(device: InputDevice, input: InputObject, gameProcessed: boolean): InputBinding?
    local inputType = input.UserInputType
    local keyCode = input.KeyCode

    if device == InputDevice.Keyboard then
        if inputType == Enum.UserInputType.Keyboard and keyCode ~= Enum.KeyCode.Unknown then
            return keyCode
        end

        -- A click the menu's own GUI already handled is the player pressing the menu, not choosing a binding.
        if MOUSE_BUTTONS[inputType] and not gameProcessed then
            return inputType
        end

        return nil
    end

    if device == InputDevice.Gamepad then
        if isGamepadInput(inputType) and keyCode ~= Enum.KeyCode.Unknown and not STICK_KEYS[keyCode] then
            return keyCode
        end
    end

    return nil
end

function BindingCapture.new(userInputService: UserInputService): BindingCapture
    local self = setmetatable({}, BindingCapture)

    self._userInputService = userInputService
    self._connection = nil
    self._onCaptured = nil

    return self :: BindingCapture
end

-- Starts waiting for the player's next press. A capture already in progress is cancelled first.
function BindingCapture.Begin(self: BindingCapture, device: InputDevice, onCaptured: CaptureCallback): ()
    if device == InputDevice.Touch then
        error("Touch has no key bindings to capture")
    end

    self:Cancel()

    self._onCaptured = onCaptured
    self._connection = self._userInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        self:_handleInput(device, input, gameProcessed)
    end)
end

-- Ends the capture without a binding. Does nothing when no capture is in progress.
function BindingCapture.Cancel(self: BindingCapture): ()
    self:_finish(nil)
end

function BindingCapture.IsCapturing(self: BindingCapture): boolean
    return self._onCaptured ~= nil
end

function BindingCapture._handleInput(self: BindingCapture, device: InputDevice, input: InputObject, gameProcessed: boolean): ()
    -- Escape is checked ignoring gameProcessed, since Roblox's own menu claims it, and it cancels for every device.
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
        self:_finish(nil)
        return
    end

    local binding = toBinding(device, input, gameProcessed)
    if binding then
        self:_finish(binding)
    end
end

-- Stops listening before calling back, so the callback is free to start the next capture.
function BindingCapture._finish(self: BindingCapture, binding: InputBinding?): ()
    local onCaptured = self._onCaptured
    if not onCaptured then
        return
    end

    self:_stopListening()
    onCaptured(binding)
end

function BindingCapture._stopListening(self: BindingCapture): ()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    self._onCaptured = nil
end

function BindingCapture.Destroy(self: BindingCapture): ()
    self:_stopListening()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BindingCapture)
return BindingCapture
