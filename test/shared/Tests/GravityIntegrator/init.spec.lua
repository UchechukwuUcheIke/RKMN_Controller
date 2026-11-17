--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local PhysicsResolverFolder = ReplicatedStorage.RKMNController.PhysicsResolver
local GravityIntegrator = require(PhysicsResolverFolder.GravityIntegrator)
local MotionState = require(PhysicsResolverFolder.MotionState)

local stats = table.freeze({
	JumpVelocity = 40,
	RiseGravity = 100,
	FallGravity = 200,
	CutGravity = 400,
	FallSpeed = 120,
})

describe("GravityIntegrator", function()
	local gravity
	local motion

	beforeEach(function()
		gravity = GravityIntegrator.new(stats)
		motion = MotionState.new()
	end)

	describe("Apply", function()
		it("should use fall gravity when not rising", function()
			gravity:Apply(motion, 0.1, false)

			expect(motion.Velocity.Y).toBeCloseTo(-20, 4)
		end)

		it("should use rise gravity while rising", function()
			motion.Velocity = Vector3.new(0, 30, 0)

			gravity:Apply(motion, 0.1, false)

			expect(motion.Velocity.Y).toBeCloseTo(20, 4)
		end)

		it("should use cut gravity while rising after CutRise", function()
			motion.Velocity = Vector3.new(0, 30, 0)
			gravity:CutRise()

			gravity:Apply(motion, 0.1, false)

			expect(motion.Velocity.Y).toBeCloseTo(-10, 4)
		end)

		it("should stop using cut gravity after ClearRiseCut", function()
			motion.Velocity = Vector3.new(0, 30, 0)
			gravity:CutRise()
			gravity:ClearRiseCut()

			gravity:Apply(motion, 0.1, false)

			expect(motion.Velocity.Y).toBeCloseTo(20, 4)
		end)

		it("should clamp fall speed at the stats FallSpeed", function()
			for _ = 1, 50 do
				gravity:Apply(motion, 1, false)
			end

			expect(motion.Velocity.Y).toBeCloseTo(-120, 4)
		end)

		it("should clamp fall speed at the override when one is set", function()
			gravity:SetFallSpeedOverride(15)

			for _ = 1, 50 do
				gravity:Apply(motion, 1, false)
			end

			expect(motion.Velocity.Y).toBeCloseTo(-15, 4)
		end)

		it("should return to the stats FallSpeed when the override is cleared", function()
			gravity:SetFallSpeedOverride(15)
			gravity:SetFallSpeedOverride(nil)

			for _ = 1, 50 do
				gravity:Apply(motion, 1, false)
			end

			expect(motion.Velocity.Y).toBeCloseTo(-120, 4)
		end)

		it("should zero Y velocity instead of accelerating while grounded and not rising", function()
			motion.Velocity = Vector3.new(0, -50, 0)

			gravity:Apply(motion, 0.1, true)

			expect(motion.Velocity.Y).toBe(0)
		end)

		it("should still apply gravity while grounded but rising", function()
			motion.Velocity = Vector3.new(0, 30, 0)

			gravity:Apply(motion, 0.1, true)

			expect(motion.Velocity.Y).toBeCloseTo(20, 4)
		end)

		it("should never touch X or Z", function()
			motion.Velocity = Vector3.new(42, 0, 0)

			gravity:Apply(motion, 0.1, false)

			expect(motion.Velocity.X).toBe(42)
			expect(motion.Velocity.Z).toBe(0)
		end)
	end)
end)
