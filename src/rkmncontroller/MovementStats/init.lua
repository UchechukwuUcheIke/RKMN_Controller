local RKMNControllerFolder = script.Parent
local MovementConfig = require(RKMNControllerFolder.MovementConfig)

local MovementStats = {}
MovementStats.__index = MovementStats

export type MovementStats = typeof(setmetatable(
	{} :: {
		Gravity: number,
	},
	{} :: typeof(MovementStats)
))

function MovementStats.new(): MovementStats
	return setmetatable({
		Gravity = 1
	}, MovementStats) :: MovementStats
end

return MovementStats
