local RKMNControllerFolder = script.Parent
local MovementConfig = require(RKMNControllerFolder.MovementConfig)

local MovementStats = {}
MovementStats.__index = MovementStats

export type MovementStats = typeof(setmetatable(
	{} :: {
		JumpVelocity: number,
		FallSpeed: number,
	},
	{} :: typeof(MovementStats)
))

function MovementStats.new(): MovementStats
	return setmetatable({
		JumpVelocity = MovementConfig.JumpHeight / MovementConfig.TimeToApex,
		FallSpeed = MovementConfig.FallSpeed,
	}, MovementStats) :: MovementStats
end

function MovementStats.Destroy(self: MovementStats): ()
end

return MovementStats
