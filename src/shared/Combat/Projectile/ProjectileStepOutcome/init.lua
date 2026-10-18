--!strict
local ProjectileStepOutcome = {
    InFlight = "InFlight",
    HitPenetrationExhausted = "HitPenetrationExhausted",
    Blocked = "Blocked",
    HitWall = "HitWall",
    Expired = "Expired"
}

export type ProjectileStepOutcome = "InFlight" | "HitPenetrationExhausted" | "Blocked" | "HitWall" | "Expired"

table.freeze(ProjectileStepOutcome)

return ProjectileStepOutcome
