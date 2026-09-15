local SweepResolution = {}
SweepResolution.__index = SweepResolution

export type SweepResolution = typeof(setmetatable(
	{} :: {
    safeDelta: Vector3,
    hitFloor: boolean,
    hitWall: boolean,
},{} :: SweepResolution))

function SweepResolution.new(safeDelta: Vector3?, hitFloor: boolean?, hitWall: boolean?) : SweepResolution
    local self = setmetatable({
	    safeDelta = safeDelta or Vector3.zero,
        hitFloor = hitFloor or false,
        hitWall = hitWall or false

	    }, SweepResolution) :: any

    return self
end

return SweepResolution