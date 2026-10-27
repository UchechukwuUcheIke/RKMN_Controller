--!strict
export type ActionID = "Left" | "Right" | "Jump" | "Dash" | "Shoot"

local InputAction = {
    Left = "Left" :: ActionID,
    Right = "Right" :: ActionID,
    Jump = "Jump" :: ActionID,
    Dash = "Dash" :: ActionID,
    Shoot = "Shoot" :: ActionID,
}

table.freeze(InputAction)

return InputAction
