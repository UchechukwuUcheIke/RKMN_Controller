--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local MobileButtonPositioner = require(ReplicatedStorage.TouchGamepad.MobileButtonPositioner)
local ActionButton = require(ReplicatedStorage.TouchGamepad.UserInterface.ActionButton)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)

local ACTIONS = { "Left", "Right", "Jump", "Dash", "Shoot", "Menu" }

describe("MobileButtonPositioner", function()
	it("applies a layout's position, size and anchor to each registered button", function()
		local positioner = MobileButtonPositioner.new()
		local jump = ActionButton.new("Jump", "Jump")
		positioner:RegisterButton("Jump", jump)

		positioner:ApplyLayout(TouchGamepadLayoutRegistry.Standard)

		local expected = TouchGamepadLayoutRegistry.Standard.Jump
		local instance = jump:GetInstance()
		expect(instance.Position).toEqual(expected.Position)
		expect(instance.Size).toEqual(expected.Size)
		expect(instance.AnchorPoint).toEqual(expected.AnchorPoint)
	end)

	it("errors, without moving anything, when a registered button has no transform", function()
		local positioner = MobileButtonPositioner.new()
		local jump = ActionButton.new("Jump", "Jump")
		local dash = ActionButton.new("Dash", "Dash")
		positioner:RegisterButton("Jump", jump)
		positioner:RegisterButton("Dash", dash)
		local startingPosition = jump:GetInstance().Position

		expect(function()
			positioner:ApplyLayout({ Jump = TouchGamepadLayoutRegistry.Standard.Jump })
		end).toThrow()

		expect(jump:GetInstance().Position).toEqual(startingPosition)
	end)

	it("has a transform for every action in the standard layout", function()
		for _, action in ipairs(ACTIONS) do
			expect(TouchGamepadLayoutRegistry.Standard[action]).never.toBeNil()
		end
	end)
end)
