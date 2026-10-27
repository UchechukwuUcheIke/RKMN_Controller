--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Direction = require(ReplicatedStorage.Data.Direction)
local DirectionResolver = require(ReplicatedStorage.PlayerInput.DirectionResolver)

describe("DirectionResolver", function()
	it("starts with no direction", function()
		expect(DirectionResolver.new():GetDirection()).toBe(Direction.None)
	end)

	it("resolves left, right and neither", function()
		local resolver = DirectionResolver.new()

		resolver:Resolve(true, false)
		expect(resolver:GetDirection()).toBe(Direction.Left)

		resolver:Resolve(false, true)
		expect(resolver:GetDirection()).toBe(Direction.Right)

		resolver:Resolve(false, false)
		expect(resolver:GetDirection()).toBe(Direction.None)
	end)

	it("cancels out when both are held", function()
		local resolver = DirectionResolver.new()
		resolver:Resolve(true, true)
		expect(resolver:GetDirection()).toBe(Direction.None)
	end)
end)
