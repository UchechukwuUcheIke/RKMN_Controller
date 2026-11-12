--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringEnum = require(ReplicatedStorage.Utility.StringEnum)

export type InputDevice = "touch" | "keyboard" | "gamepad" | "unknown"

-- Values are lowercase because they are stored in the bug report tables. Unknown is for a report from a
-- client the game could not classify; gameplay input never resolves to it.
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
