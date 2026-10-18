--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Bounds = require(ReplicatedStorage.Combat.Bounds)

local function box(x: number, y: number, width: number, height: number)
	return Bounds.new(Vector2.new(x, y), Vector2.new(width, height))
end

describe("Bounds.overlaps", function()
	it("detects boxes that intersect", function()
		expect(Bounds.overlaps(box(0, 0, 4, 4), box(3, 0, 4, 4))).toBe(true)
	end)

	it("rejects boxes that are apart on X", function()
		expect(Bounds.overlaps(box(0, 0, 4, 4), box(10, 0, 4, 4))).toBe(false)
	end)

	it("rejects boxes that are apart on Y", function()
		expect(Bounds.overlaps(box(0, 0, 4, 4), box(0, 10, 4, 4))).toBe(false)
	end)

	it("counts boxes touching along an edge as overlapping", function()
		expect(Bounds.overlaps(box(0, 0, 4, 4), box(4, 0, 4, 4))).toBe(true)
	end)

	it("detects a box fully inside another", function()
		expect(Bounds.overlaps(box(0, 0, 20, 20), box(1, 1, 2, 2))).toBe(true)
	end)
end)

describe("Bounds.fromSweep", function()
	it("covers the start, the end, and the size of the moving box", function()
		local swept = Bounds.fromSweep(Vector2.new(0, 0), Vector2.new(10, 0), Vector2.new(2, 4))
		expect(swept.Center).toBe(Vector2.new(5, 0))
		expect(swept.Size).toBe(Vector2.new(12, 4))
	end)

	it("works when moving in the negative direction", function()
		local swept = Bounds.fromSweep(Vector2.new(10, 5), Vector2.new(0, 5), Vector2.new(2, 2))
		expect(swept.Center).toBe(Vector2.new(5, 5))
		expect(swept.Size).toBe(Vector2.new(12, 2))
	end)

	it("is just the box itself when it did not move", function()
		local swept = Bounds.fromSweep(Vector2.new(3, 3), Vector2.new(3, 3), Vector2.new(2, 2))
		expect(swept.Center).toBe(Vector2.new(3, 3))
		expect(swept.Size).toBe(Vector2.new(2, 2))
	end)
end)
