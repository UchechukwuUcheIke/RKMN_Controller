--!strict
local MotionState = {}
MotionState.__index = MotionState
MotionState.ClassName = "MotionState"

local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

type Direction = Direction.Direction

type MotionStateData = {
	Velocity: Vector3,
	TargetXVelocity: number,
	FacingDirection: Direction,
}

type MotionStatePrototype = typeof({__index = MotionState})

export type MotionState = typeof(setmetatable(
	{} :: MotionStateData,
	{} :: MotionStatePrototype))

function MotionState.new(): MotionState
	local data: MotionStateData = {
		Velocity = Vector3.zero,
		TargetXVelocity = 0,
		FacingDirection = Direction.Right,
	}

	return setmetatable(data, MotionState)
end

function MotionState.SetTargetXVelocity(self: MotionState, xVelocity: number, facingDirection: Direction): ()
	self.TargetXVelocity = xVelocity
	if facingDirection ~= Direction.None then
		self.FacingDirection = facingDirection
	end
end

function MotionState.ApplyHorizontalTarget(self: MotionState): ()
	self.Velocity = Vector3.new(self.TargetXVelocity, self.Velocity.Y, 0)
end

function MotionState.SetVelocityY(self: MotionState, yVelocity: number): ()
	self.Velocity = Vector3.new(self.Velocity.X, yVelocity, 0)
end

function MotionState.ZeroVelocityX(self: MotionState): ()
	self.Velocity = Vector3.new(0, self.Velocity.Y, 0)
end

function MotionState.ZeroVelocityY(self: MotionState): ()
	self.Velocity = Vector3.new(self.Velocity.X, 0, 0)
end

function MotionState.ComputeFrameDelta(self: MotionState, previousYVelocity: number, dt: number): Vector3
	local averageYVelocity = (previousYVelocity + self.Velocity.Y) / 2
	return Vector3.new(self.Velocity.X, averageYVelocity, 0) * dt
end

table.freeze(MotionState)

return MotionState
