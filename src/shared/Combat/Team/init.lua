--!strict
local Team = {
	Player = "Player",
	Enemy = "Enemy",
	Neutral = "Neutral",
}

export type Team = "Player" | "Enemy" | "Neutral"

local HURTS: { [Team]: { [Team]: boolean } } = {
	Player = { Enemy = true, Neutral = true },
	Enemy = { Player = true },
	Hazard = { Player = true, Enemy = true },
	Neutral = {},
}

function Team.canHurt(attacker: Team, target: Team): boolean
	return HURTS[attacker][target] == true
end

table.freeze(Team)

return Team
