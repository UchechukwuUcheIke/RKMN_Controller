--!strict
local PhysicsResolverFolder = script.Parent
local RKMNControllerFolder = PhysicsResolverFolder.Parent
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local MotionState = require(PhysicsResolverFolder.MotionState)

type SweepResolution = SweepResolution.SweepResolution
type MotionState = MotionState.MotionState

local VelocityClipper = {}

function VelocityClipper.Clip(motion: MotionState, sweepResolution: SweepResolution): ()
	local hits = sweepResolution.SurfaceHits
	if hits.HitWall then
		motion:ZeroVelocityX()
	end

	if hits.HitFloor or hits.HitCeiling then
		motion:ZeroVelocityY()
	end
end

return table.freeze(VelocityClipper)
