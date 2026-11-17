--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local SlopeClassifier = require(ReplicatedStorage.RKMNController.CollisionQuery.SlopeClassifier)

local function normalTiltedFromUp(degrees)
	local angle = math.rad(degrees)
	return Vector3.new(-math.sin(angle), math.cos(angle), 0)
end

describe("SlopeClassifier", function()
	local classifier = SlopeClassifier.new(45)

	describe("IsSurfaceWalkable", function()
		it("should accept a flat surface", function()
			expect(classifier:IsSurfaceWalkable(Vector3.yAxis)).toBe(true)
		end)

		it("should accept a slope below the max angle", function()
			expect(classifier:IsSurfaceWalkable(normalTiltedFromUp(30))).toBe(true)
		end)

		it("should reject a slope steeper than the max angle", function()
			expect(classifier:IsSurfaceWalkable(normalTiltedFromUp(70))).toBe(false)
		end)

		it("should reject a vertical wall", function()
			expect(classifier:IsSurfaceWalkable(Vector3.xAxis)).toBe(false)
		end)

		it("should reject a ceiling", function()
			expect(classifier:IsSurfaceWalkable(-Vector3.yAxis)).toBe(false)
		end)
	end)

	describe("IsSurfaceCeiling", function()
		it("should accept a flat underside", function()
			expect(classifier:IsSurfaceCeiling(-Vector3.yAxis)).toBe(true)
		end)

		it("should reject a floor", function()
			expect(classifier:IsSurfaceCeiling(Vector3.yAxis)).toBe(false)
		end)

		it("should reject a vertical wall", function()
			expect(classifier:IsSurfaceCeiling(Vector3.xAxis)).toBe(false)
		end)
	end)
end)
