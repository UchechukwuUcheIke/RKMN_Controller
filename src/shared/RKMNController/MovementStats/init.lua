local RKMNControllerFolder = script.Parent
local MovementConfig = require(RKMNControllerFolder.MovementConfig)

local MovementStats = {}
MovementStats.__index = MovementStats

export type MovementStats = typeof(setmetatable(
	{} :: {
		JumpVelocity: number,
		RiseGravity: number,
		FallGravity: number,
		CutGravity: number,
		FallSpeed: number,
	},
	{} :: typeof(MovementStats)
))

function MovementStats.new(): MovementStats
	local riseGravity = 2 * MovementConfig.JumpHeight / MovementConfig.TimeToApex ^ 2

	return setmetatable({
		JumpVelocity = 2 * MovementConfig.JumpHeight / MovementConfig.TimeToApex,
		RiseGravity = riseGravity,
		FallGravity = riseGravity * MovementConfig.FallGravityMultiplier,
		CutGravity = riseGravity * MovementConfig.JumpCutGravityMultiplier,
		FallSpeed = MovementConfig.FallSpeed,
	}, MovementStats) :: MovementStats
end

function MovementStats.Destroy(self: MovementStats): ()
end

return MovementStats
