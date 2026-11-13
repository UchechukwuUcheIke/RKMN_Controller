export type MovementStateID = string

local MovementStateIDs = {
    Dash = "Dash",
    Walk = "Walk",
    Idle = "Idle",
    WallSlide = "WallSlide",
    Stun = "Stun",
    Jump = "Jump",
    Freefall = "Freefall"
}

table.freeze(MovementStateIDs)

return MovementStateIDs
