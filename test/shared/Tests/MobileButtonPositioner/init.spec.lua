--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local MobileButtonPositioner = require(ReplicatedStorage.TouchGamepad.MobileButtonPositioner)
local ActionButton = require(ReplicatedStorage.TouchGamepad.UserInterface.ActionButton)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)

local CONTROLS = { "DPad", "Jump", "Dash", "Shoot", "Menu" }

describe("MobileButtonPositioner", function()
	it("applies a layout's position, size and anchor to each registered control", function()
		local positioner = MobileButtonPositioner.new()
		local jump = ActionButton.new("Jump", "Jump")
		positioner:RegisterControl("Jump", jump)

		positioner:ApplyLayout(TouchGamepadLayoutRegistry.Standard)

		local expected = TouchGamepadLayoutRegistry.Standard.Jump
		local instance = jump:GetInstance()
		expect(instance.Position).toEqual(expected.Position)
		expect(instance.Size).toEqual(expected.BaseSize)
		expect(instance.AnchorPoint).toEqual(expected.AnchorPoint)
		expect(instance.BackgroundTransparency).toBe(expected.Transparency)
	end)

	it("multiplies the base size by the layout's scale", function()
		local positioner = MobileButtonPositioner.new()
		local jump = ActionButton.new("Jump", "Jump")
		positioner:RegisterControl("Jump", jump)
		local transform = {
			Position = UDim2.fromOffset(10, 10),
			BaseSize = UDim2.fromOffset(80, 60),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Scale = 1.5,
			Transparency = 0.25,
		}

		positioner:ApplyLayout({ Jump = transform })

		expect(jump:GetInstance().Size).toEqual(UDim2.fromOffset(120, 90))
		expect(jump:GetInstance().BackgroundTransparency).toBe(0.25)
	end)

	it("errors, without moving anything, when a registered control has no transform", function()
		local positioner = MobileButtonPositioner.new()
		local jump = ActionButton.new("Jump", "Jump")
		local dash = ActionButton.new("Dash", "Dash")
		positioner:RegisterControl("Jump", jump)
		positioner:RegisterControl("Dash", dash)
		local startingPosition = jump:GetInstance().Position

		expect(function()
			positioner:ApplyLayout({ Jump = TouchGamepadLayoutRegistry.Standard.Jump })
		end).toThrow()

		expect(jump:GetInstance().Position).toEqual(startingPosition)
	end)

	it("has a transform for every control in the standard layout", function()
		for _, control in ipairs(CONTROLS) do
			expect(TouchGamepadLayoutRegistry.Standard[control]).never.toBeNil()
		end
	end)

	it("keeps every standard scale and transparency inside the player's limits", function()
		local rules = require(ReplicatedStorage.TouchGamepad.ButtonTransformRules)

		for _, transform in pairs(TouchGamepadLayoutRegistry.Standard) do
			expect(transform.Scale).toBe(rules.ClampScale(transform.Scale))
			expect(transform.Transparency).toBe(rules.ClampTransparency(transform.Transparency))
		end
	end)
end)
