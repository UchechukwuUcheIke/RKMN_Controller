--!strict
local Bounds = {}

export type Bounds = {
	Center: Vector2,
	Size: Vector2,
}

function Bounds.new(center: Vector2, size: Vector2): Bounds
	return {
		Center = center,
		Size = size,
	}
end

function Bounds.overlaps(a: Bounds, b: Bounds): boolean
	local distance = (a.Center - b.Center)
	local touchingDistance = (a.Size + b.Size) / 2

	return math.abs(distance.X) <= touchingDistance.X and math.abs(distance.Y) <= touchingDistance.Y
end

function Bounds.fromSweep(from: Vector2, to: Vector2, size: Vector2): Bounds
	local halfSize = size / 2
	local min = Vector2.new(math.min(from.X, to.X), math.min(from.Y, to.Y)) - halfSize
	local max = Vector2.new(math.max(from.X, to.X), math.max(from.Y, to.Y)) + halfSize

	return Bounds.new((min + max) / 2, max - min)
end

return Bounds
