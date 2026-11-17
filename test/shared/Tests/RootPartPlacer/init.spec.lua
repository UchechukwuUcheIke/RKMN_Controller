--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local RootPartPlacer = require(ReplicatedStorage.RKMNController.PhysicsResolver.RootPartPlacer)
local Direction = require(ReplicatedStorage.Data.Direction)

describe("RootPartPlacer", function()
	local rootPart
	local placer

	beforeEach(function()
		rootPart = Instance.new("Part")
		rootPart.Anchored = false
		rootPart.CFrame = CFrame.new(0, 10, 0)
		placer = RootPartPlacer.new(rootPart)
	end)

	afterEach(function()
		rootPart:Destroy()
	end)

	describe("new", function()
		it("should anchor the root part so Roblox's own physics never fights the resolver", function()
			expect(rootPart.Anchored).toBe(true)
		end)
	end)

	describe("Place", function()
		it("should move the root part by exactly the safe delta", function()
			placer:Place(Vector3.new(1, -2, 0), Direction.Right)

			local position = rootPart.CFrame.Position
			expect(position.X).toBeCloseTo(1, 4)
			expect(position.Y).toBeCloseTo(8, 4)
			expect(position.Z).toBeCloseTo(0, 4)
		end)

		it("should face the given direction", function()
			placer:Place(Vector3.zero, Direction.Left)

			expect(rootPart.CFrame.LookVector.X).toBeCloseTo(-1, 4)
		end)
	end)

	describe("Release", function()
		it("should un-anchor the root part", function()
			placer:Release()

			expect(rootPart.Anchored).toBe(false)
		end)
	end)
end)
