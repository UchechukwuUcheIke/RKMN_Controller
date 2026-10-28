--!strict
local InputAction = require(script.Parent.InputAction)
local InputSchemeModule = require(script.Parent.InputScheme)
type InputScheme = InputSchemeModule.InputScheme

local KeyboardSchemes = {}

-- 1. Standard PC Layout (WASD / Arrows + Mouse / Keys)
KeyboardSchemes.Standard = {
    [InputAction.Left]  = { [Enum.KeyCode.A] = true, [Enum.KeyCode.Left] = true },
    [InputAction.Right] = { [Enum.KeyCode.D] = true, [Enum.KeyCode.Right] = true },
    [InputAction.Jump]  = { [Enum.KeyCode.Space] = true },
    [InputAction.Dash]  = { [Enum.KeyCode.LeftShift] = true },
    [InputAction.Shoot] = { [Enum.UserInputType.MouseButton1] = true, [Enum.KeyCode.C] = true }
} :: InputScheme

-- 2. Retro PC Layout (Keyboard Only - Classic Mega Man X style)
KeyboardSchemes.Retro = {
    [InputAction.Left]  = { [Enum.KeyCode.Left] = true },
    [InputAction.Right] = { [Enum.KeyCode.Right] = true },
    [InputAction.Jump]  = { [Enum.KeyCode.Z] = true },
    [InputAction.Dash]  = { [Enum.KeyCode.C] = true },
    [InputAction.Shoot] = { [Enum.KeyCode.X] = true }
} :: InputScheme

table.freeze(KeyboardSchemes)
return KeyboardSchemes
