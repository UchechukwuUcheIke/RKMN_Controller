local VerticalFollow = {
    Locked = "Locked",
    Deadzone = "Deadzone",
    Tracking = "Tracking",
}

-- TODO: Use a type function instead https://luau.org/types/type-functions/
export type VerticalFollow = "Locked" | "Deadzone" | "Tracking"

return VerticalFollow
