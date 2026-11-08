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

	it("turns transparency into the opacity the player sees and back", function()
		expect(ButtonTransformRules.TransparencyToOpacity(0.25)).toBe(0.75)
		expect(ButtonTransformRules.OpacityToTransparency(0.75)).toBe(0.25)
		expect(ButtonTransformRules.MAX_OPACITY).toBe(1)
		expect(ButtonTransformRules.MIN_OPACITY).toBeCloseTo(0.2)
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

	it("works out a control's size in pixels from the viewport, scale and offset together", function()
		local transform = {
			Position = UDim2.new(),
			BaseSize = UDim2.new(0.5, 100, 0.25, 40),
			AnchorPoint = Vector2.new(),
			Scale = 2,
			Transparency = 0,
		}

		local result = ButtonTransformRules.GetEffectivePixelSize(transform, Vector2.new(1000, 400))

		expect(result).toEqual(Vector2.new(1200, 280))
	end)

	describe("ClampPosition", function()
		local viewport = Vector2.new(1024, 512)
		local size = Vector2.new(128, 64)
		local centered = Vector2.new(0.5, 0.5)

		it("leaves a position that is fully on screen alone", function()
			local result = ButtonTransformRules.ClampPosition(Vector2.new(0.4, 0.6), size, centered, viewport)

			expect(result).toEqual(Vector2.new(0.4, 0.6))
		end)

		it("keeps a centered control's edges on screen", function()
			local result = ButtonTransformRules.ClampPosition(Vector2.new(-1, 2), size, centered, viewport)

			expect(result).toEqual(Vector2.new(0.0625, 0.9375))
		end)

		it("accounts for the anchor point", function()
			local topLeftAnchor = Vector2.new(0, 0)
			local result = ButtonTransformRules.ClampPosition(Vector2.new(2, 2), size, topLeftAnchor, viewport)

			expect(result).toEqual(Vector2.new(0.875, 0.875))
		end)

		it("centers a control that is bigger than the viewport", function()
			local huge = Vector2.new(2048, 64)
			local result = ButtonTransformRules.ClampPosition(Vector2.new(0.1, 0.5), huge, centered, viewport)

			expect(result.X).toBe(0.5)
		end)

		it("returns the position unchanged when the viewport has no size", function()
			local result = ButtonTransformRules.ClampPosition(Vector2.new(3, 3), size, centered, Vector2.new())

			expect(result).toEqual(Vector2.new(3, 3))
		end)
	end)
end)
