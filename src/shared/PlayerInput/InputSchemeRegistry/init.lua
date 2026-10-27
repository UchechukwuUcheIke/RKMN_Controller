--!strict
local PlayerInputFolder = script.Parent
local InputAction = require(PlayerInputFolder.InputAction)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)

type InputScheme = InputSchemeTypes.InputScheme

local InputSchemeRegistry = {}

local function freezeScheme(scheme: InputScheme): InputScheme
    for _, bindings in pairs(scheme) do
        table.freeze(bindings)
    end
    return table.freeze(scheme)
end

InputSchemeRegistry.Standard = freezeScheme({
    [InputAction.Left]  = { [Enum.KeyCode.A] = true, [Enum.KeyCode.Left] = true, [Enum.KeyCode.DPadLeft] = true },
    [InputAction.Right] = { [Enum.KeyCode.D] = true, [Enum.KeyCode.Right] = true, [Enum.KeyCode.DPadRight] = true },
    [InputAction.Jump]  = { [Enum.KeyCode.Space] = true, [Enum.KeyCode.ButtonA] = true },
    [InputAction.Dash]  = { [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.ButtonX] = true },
    [InputAction.Shoot] = { [Enum.UserInputType.MouseButton1] = true, [Enum.KeyCode.C] = true, [Enum.KeyCode.ButtonB] = true }
})

InputSchemeRegistry.BumperJumper = freezeScheme({
    [InputAction.Left]  = { [Enum.KeyCode.A] = true, [Enum.KeyCode.Left] = true, [Enum.KeyCode.DPadLeft] = true },
    [InputAction.Right] = { [Enum.KeyCode.D] = true, [Enum.KeyCode.Right] = true, [Enum.KeyCode.DPadRight] = true },
    [InputAction.Jump]  = { [Enum.KeyCode.Space] = true, [Enum.KeyCode.ButtonL1] = true },
    [InputAction.Dash]  = { [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.ButtonR1] = true },
    [InputAction.Shoot] = { [Enum.UserInputType.MouseButton1] = true, [Enum.KeyCode.ButtonX] = true }
})

InputSchemeRegistry.RetroPC = freezeScheme({
    [InputAction.Left]  = { [Enum.KeyCode.Left] = true },
    [InputAction.Right] = { [Enum.KeyCode.Right] = true },
    [InputAction.Jump]  = { [Enum.KeyCode.Z] = true },
    [InputAction.Dash]  = { [Enum.KeyCode.C] = true },
    [InputAction.Shoot] = { [Enum.KeyCode.X] = true }
})

table.freeze(InputSchemeRegistry)

return InputSchemeRegistry
