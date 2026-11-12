--!strict
export type InputDevice = "touch" | "keyboard" | "gamepad" | "unknown"

local InputDevice = {
    Touch = "touch" :: InputDevice,
    Keyboard = "keyboard" :: InputDevice,
    Gamepad = "gamepad" :: InputDevice,
    Unknown = "unknown" :: InputDevice,
}

local VALID_VALUES: {[string]: boolean} = {}
for _, value in InputDevice do
    VALID_VALUES[value] = true
end
table.freeze(VALID_VALUES)

function InputDevice.IsValid(value: any): boolean
    return typeof(value) == "string" and VALID_VALUES[value] == true
end

table.freeze(InputDevice)
return InputDevice
