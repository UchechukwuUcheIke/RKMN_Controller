--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ButtonTransform = require(ReplicatedStorage.TouchGamepad.ButtonTransform)

local function makeProps()
	return {
		Position = UDim2.fromScale(0.5, 0.5),
		BaseSize = UDim2.fromOffset(80, 80),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Scale = 1,
		Transparency = 0.5,
	}
end

describe("ButtonTransform", function()
	it("holds the values it was made with and is frozen", function()
		local transform = ButtonTransform.new(makeProps())

		expect(transform.Position).toEqual(UDim2.fromScale(0.5, 0.5))
		expect(transform.BaseSize).toEqual(UDim2.fromOffset(80, 80))
		expect(transform.AnchorPoint).toEqual(Vector2.new(0.5, 0.5))
		expect(transform.Scale).toBe(1)
		expect(transform.Transparency).toBe(0.5)
		expect(table.isfrozen(transform)).toBe(true)
	end)

	describe("CopyWithChanges", function()
		it("returns a new transform with only the given fields replaced", function()
			local original = ButtonTransform.new(makeProps())

			local changed = original:CopyWithChanges({ Scale = 1.5, Position = UDim2.fromScale(0.1, 0.2) })

			expect(changed.Scale).toBe(1.5)
			expect(changed.Position).toEqual(UDim2.fromScale(0.1, 0.2))
			expect(changed.BaseSize).toEqual(original.BaseSize)
			expect(changed.Transparency).toBe(0.5)
		end)

		it("leaves the original alone", function()
			local original = ButtonTransform.new(makeProps())

			original:CopyWithChanges({ Scale = 1.5 })

			expect(original.Scale).toBe(1)
		end)

		it("can set a transparency of zero", function()
			local original = ButtonTransform.new(makeProps())

			expect(original:CopyWithChanges({ Transparency = 0 }).Transparency).toBe(0)
		end)
	end)

	describe("Equals", function()
		it("is true for transforms with the same values, even when they are separate objects", function()
			local first = ButtonTransform.new(makeProps())
			local second = ButtonTransform.new(makeProps())

			expect(first:Equals(second)).toBe(true)
		end)

		it("is false when any one field differs", function()
			local original = ButtonTransform.new(makeProps())

			expect(original:Equals(original:CopyWithChanges({ Position = UDim2.fromScale(0.1, 0.5) }))).toBe(false)
			expect(original:Equals(original:CopyWithChanges({ BaseSize = UDim2.fromOffset(90, 80) }))).toBe(false)
			expect(original:Equals(original:CopyWithChanges({ AnchorPoint = Vector2.new(0, 0) }))).toBe(false)
			expect(original:Equals(original:CopyWithChanges({ Scale = 1.1 }))).toBe(false)
			expect(original:Equals(original:CopyWithChanges({ Transparency = 0.6 }))).toBe(false)
		end)
	end)
end)
