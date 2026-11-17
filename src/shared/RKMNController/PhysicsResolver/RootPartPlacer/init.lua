--!strict
local RootPartPlacer = {}
RootPartPlacer.__index = RootPartPlacer
RootPartPlacer.ClassName = "RootPartPlacer"

local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

type Direction = Direction.Direction

type RootPartPlacerData = {
	_rootPart: BasePart,
}

type RootPartPlacerPrototype = typeof({__index = RootPartPlacer})

export type RootPartPlacer = typeof(setmetatable(
	{} :: RootPartPlacerData,
	{} :: RootPartPlacerPrototype))

function RootPartPlacer.new(rootPart: BasePart): RootPartPlacer
	rootPart.Anchored = true

	local data: RootPartPlacerData = {
		_rootPart = rootPart,
	}

	return setmetatable(data, RootPartPlacer)
end

function RootPartPlacer.Place(self: RootPartPlacer, safeDelta: Vector3, facingDirection: Direction): ()
	local nextPosition = self._rootPart.CFrame.Position + safeDelta
	self._rootPart.CFrame = CFrame.lookAt(nextPosition, nextPosition + facingDirection)
end

function RootPartPlacer.Release(self: RootPartPlacer): ()
	self._rootPart.Anchored = false
end

table.freeze(RootPartPlacer)

return RootPartPlacer
