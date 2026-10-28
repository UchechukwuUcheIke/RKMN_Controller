--!strict
export type InputDevice = "Keyboard" | "Gamepad" | "Touch"

local InputDevice = {
    Keyboard = "Keyboard" :: InputDevice,
    Gamepad = "Gamepad" :: InputDevice,
    Touch = "Touch" :: InputDevice,
}

table.freeze(InputDevice)

return InputDevice
