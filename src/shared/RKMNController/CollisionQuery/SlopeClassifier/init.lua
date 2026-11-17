--!strict
local SlopeClassifier = {}
SlopeClassifier.__index = SlopeClassifier
SlopeClassifier.ClassName = "SlopeClassifier"

type SlopeClassifierData = {
	_maxSlopeDot: number,
}

type SlopeClassifierPrototype = typeof({__index = SlopeClassifier})

export type SlopeClassifier = typeof(setmetatable(
	{} :: SlopeClassifierData,
	{} :: SlopeClassifierPrototype))

function SlopeClassifier.new(maxSlopeAngle: number): SlopeClassifier
	local data: SlopeClassifierData = {
		_maxSlopeDot = math.cos(math.rad(maxSlopeAngle)),
	}

	return setmetatable(data, SlopeClassifier)
end

function SlopeClassifier.IsSurfaceWalkable(self: SlopeClassifier, normal: Vector3): boolean
	return normal:Dot(Vector3.yAxis) >= self._maxSlopeDot
end

function SlopeClassifier.IsSurfaceCeiling(self: SlopeClassifier, normal: Vector3): boolean
	return (-normal):Dot(Vector3.yAxis) >= self._maxSlopeDot
end

table.freeze(SlopeClassifier)

return SlopeClassifier
