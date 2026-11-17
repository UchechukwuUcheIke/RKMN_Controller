--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local MotionState = require(ReplicatedStorage.RKMNController.PhysicsResolver.MotionState)
local Direction = require(ReplicatedStorage.Data.Direction)

describe("MotionState", function()
	local motion

	beforeEach(function()
		motion = MotionState.new()
	end)

	describe("new", function()
		it("should start at zero velocity, facing Direction.Right, with zero target velocity", function()
			expect(motion.Velocity).toEqual(Vector3.zero)
			expect(motion.FacingDirection).toBe(Direction.Right)
			expect(motion.TargetXVelocity).toBe(0)
		end)
	end)

	describe("SetTargetXVelocity", function()
		it("should update TargetXVelocity", function()
			motion:SetTargetXVelocity(25, Direction.Right)

			expect(motion.TargetXVelocity).toBe(25)
		end)

		it("should update FacingDirection when a real direction is given", function()
			motion:SetTargetXVelocity(-25, Direction.Left)

			expect(motion.FacingDirection).toBe(Direction.Left)
		end)

		it("should leave FacingDirection unchanged when Direction.None is given", function()
			motion:SetTargetXVelocity(10, Direction.Right)
			motion:SetTargetXVelocity(0, Direction.None)

			expect(motion.FacingDirection).toBe(Direction.Right)
		end)
	end)

	describe("ApplyHorizontalTarget", function()
		it("should snap X velocity straight to the target without touching Y or Z", function()
			motion:SetTargetXVelocity(60, Direction.Right)
			motion.Velocity = Vector3.new(0, -5, 0)

			motion:ApplyHorizontalTarget()

			expect(motion.Velocity.X).toBe(60)
			expect(motion.Velocity.Y).toBe(-5)
			expect(motion.Velocity.Z).toBe(0)
		end)
	end)

	describe("SetVelocityY", function()
		it("should replace Y and keep X", function()
			motion.Velocity = Vector3.new(7, 1, 0)

			motion:SetVelocityY(30)

			expect(motion.Velocity).toEqual(Vector3.new(7, 30, 0))
		end)
	end)

	describe("ZeroVelocityX / ZeroVelocityY", function()
		it("should zero X only", function()
			motion.Velocity = Vector3.new(30, -20, 0)

			motion:ZeroVelocityX()

			expect(motion.Velocity).toEqual(Vector3.new(0, -20, 0))
		end)

		it("should zero Y only", function()
			motion.Velocity = Vector3.new(30, -20, 0)

			motion:ZeroVelocityY()

			expect(motion.Velocity).toEqual(Vector3.new(30, 0, 0))
		end)
	end)

	describe("ComputeFrameDelta", function()
		it("should use the current X velocity", function()
			motion.Velocity = Vector3.new(10, 0, 0)

			local delta = motion:ComputeFrameDelta(0, 0.5)

			expect(delta.X).toBeCloseTo(5, 4)
		end)

		it("should average the previous and current Y velocity", function()
			motion.Velocity = Vector3.new(0, -10, 0)

			local delta = motion:ComputeFrameDelta(10, 1)

			expect(delta.Y).toBeCloseTo(0, 4)
		end)

		it("should scale Y by dt", function()
			motion.Velocity = Vector3.new(0, -20, 0)

			local delta = motion:ComputeFrameDelta(-20, 0.1)

			expect(delta.Y).toBeCloseTo(-2, 4)
			expect(delta.Z).toBe(0)
		end)
	end)
end)
