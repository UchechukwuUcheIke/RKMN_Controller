--!strict
export type ActionID = "Left" | "Right" | "Jump" | "Dash" | "Shoot" | "Menu"

local InputAction = {
    Left = "Left" :: ActionID,
    Right = "Right" :: ActionID,
    Jump = "Jump" :: ActionID,
    Dash = "Dash" :: ActionID,
    Shoot = "Shoot" :: ActionID,
    Menu = "Menu" :: ActionID,
}

table.freeze(InputAction)

return InputAction
