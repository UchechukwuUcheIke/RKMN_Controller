--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local VelocityClipper = require(RKMNControllerFolder.PhysicsResolver.VelocityClipper)
local MotionState = require(RKMNControllerFolder.PhysicsResolver.MotionState)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local SurfaceHits = require(RKMNControllerFolder.SurfaceHits)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)

local function makeResolution(hits)
	local castRecord = DiagnosticCastRecord.fromBlockcast(false, CFrame.new(), Vector3.one, Vector3.zero)
	return SweepResolution.new(castRecord, Vector3.zero, hits)
end

describe("VelocityClipper", function()
	local motion

	beforeEach(function()
		motion = MotionState.new()
		motion.Velocity = Vector3.new(30, -20, 0)
	end)

	describe("Clip", function()
		it("should zero X on a wall hit but leave Y alone", function()
			VelocityClipper.Clip(motion, makeResolution(SurfaceHits.new(false, true, false)))

			expect(motion.Velocity.X).toBe(0)
			expect(motion.Velocity.Y).toBe(-20)
		end)

		it("should zero Y on a floor hit but leave X alone", function()
			VelocityClipper.Clip(motion, makeResolution(SurfaceHits.new(true, false, false)))

			expect(motion.Velocity.X).toBe(30)
			expect(motion.Velocity.Y).toBe(0)
		end)

		it("should zero Y on a ceiling hit but leave X alone", function()
			VelocityClipper.Clip(motion, makeResolution(SurfaceHits.new(false, false, true)))

			expect(motion.Velocity.X).toBe(30)
			expect(motion.Velocity.Y).toBe(0)
		end)

		it("should leave velocity untouched when nothing was hit", function()
			VelocityClipper.Clip(motion, makeResolution(SurfaceHits.new()))

			expect(motion.Velocity).toEqual(Vector3.new(30, -20, 0))
		end)

		it("should not react to a ledge hit alone", function()
			VelocityClipper.Clip(motion, makeResolution(SurfaceHits.new(false, false, false, true)))

			expect(motion.Velocity).toEqual(Vector3.new(30, -20, 0))
		end)
	end)
end)
