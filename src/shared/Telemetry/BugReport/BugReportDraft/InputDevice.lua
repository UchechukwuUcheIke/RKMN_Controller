--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringEnum = require(ReplicatedStorage.Utility.StringEnum)

export type InputDevice = "touch" | "keyboard" | "gamepad" | "unknown"

local InputDevice = {
    Touch = "touch" :: InputDevice,
    Keyboard = "keyboard" :: InputDevice,
    Gamepad = "gamepad" :: InputDevice,
    Unknown = "unknown" :: InputDevice,
}

function InputDevice.IsValid(value: any): boolean
    return StringEnum.Contains(InputDevice, value)
end

table.freeze(InputDevice)
return InputDevice
