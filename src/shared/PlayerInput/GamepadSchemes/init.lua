--!strict
local InputAction = require(script.Parent.InputAction)
local InputSchemeModule = require(script.Parent.InputScheme)
type InputScheme = InputSchemeModule.InputScheme

local GamepadSchemes = {}

GamepadSchemes.Standard = {
    [InputAction.Left]  = { [Enum.KeyCode.DPadLeft] = true },
    [InputAction.Right] = { [Enum.KeyCode.DPadRight] = true },
    [InputAction.Jump]  = { [Enum.KeyCode.ButtonA] = true },
    [InputAction.Dash]  = { [Enum.KeyCode.ButtonX] = true },
    [InputAction.Shoot] = { [Enum.KeyCode.ButtonB] = true, [Enum.KeyCode.ButtonR2] = true } -- Added R2 as a modern shooter standard
} :: InputScheme

GamepadSchemes.BumperJumper = {
    [InputAction.Left]  = { [Enum.KeyCode.DPadLeft] = true },
    [InputAction.Right] = { [Enum.KeyCode.DPadRight] = true },
    [InputAction.Jump]  = { [Enum.KeyCode.ButtonL1] = true },
    [InputAction.Dash]  = { [Enum.KeyCode.ButtonR1] = true },
    [InputAction.Shoot] = { [Enum.KeyCode.ButtonX] = true }
} :: InputScheme

table.freeze(GamepadSchemes)
return GamepadSchemes
