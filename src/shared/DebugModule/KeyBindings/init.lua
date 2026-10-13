local KeyBindings = {
    ToggleDebug = {
        [Enum.KeyCode.BackSlash] = true
    },
    Pause = {
        [Enum.KeyCode.P] = true
    },
    StepForward = {
        [Enum.KeyCode.RightBracket] = true
    },
}

export type KeyBindings = typeof(KeyBindings)

return KeyBindings