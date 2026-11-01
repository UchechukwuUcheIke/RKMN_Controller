--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ButtonTransformRules = require(ReplicatedStorage.TouchGamepad.ButtonTransformRules)

describe("ButtonTransformRules", function()
	it("clamps scale to 50% through 150%", function()
		expect(ButtonTransformRules.ClampScale(0.1)).toBe(0.5)
		expect(ButtonTransformRules.ClampScale(1)).toBe(1)
		expect(ButtonTransformRules.ClampScale(3)).toBe(1.5)
	end)

	it("clamps transparency so opacity stays between 0.2 and 1.0", function()
		expect(ButtonTransformRules.ClampTransparency(-0.5)).toBe(0)
		expect(ButtonTransformRules.ClampTransparency(0.5)).toBe(0.5)
		expect(ButtonTransformRules.ClampTransparency(1)).toBe(0.8)
	end)

	it("scales both the scale and offset parts of the size", function()
		local transform = {
			Position = UDim2.new(),
			BaseSize = UDim2.new(0.5, 100, 0.25, 40),
			AnchorPoint = Vector2.new(),
			Scale = 2,
			Transparency = 0,
		}

		expect(ButtonTransformRules.GetEffectiveSize(transform)).toEqual(UDim2.new(1, 200, 0.5, 80))
	end)
end)
