--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TouchLayoutPresets = require(ReplicatedStorage.TouchGamepad.TouchLayoutPresets)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local ButtonTransformRules = require(ReplicatedStorage.TouchGamepad.ButtonTransformRules)

local STANDARD = TouchGamepadLayoutRegistry.Standard

describe("TouchLayoutPresets", function()
	it("starts with the standard layout", function()
		local first = TouchLayoutPresets.All[1]

		expect(first.Id).toBe(TouchLayoutPresets.StandardID)
		expect(first.Layout).toBe(STANDARD)
	end)

	it("gives every preset a unique id and a name", function()
		local seen = {}

		for _, preset in ipairs(TouchLayoutPresets.All) do
			expect(seen[preset.Id]).toBeNil()
			seen[preset.Id] = true
			expect(#preset.Name > 0).toBe(true)
		end
	end)

	it("places every control the standard layout does, and no others", function()
		for _, preset in ipairs(TouchLayoutPresets.All) do
			expect(preset.Layout:HasAllControlsOf(STANDARD)).toBe(true)
			expect(STANDARD:HasAllControlsOf(preset.Layout)).toBe(true)
		end
	end)

	it("keeps every preset's scale and transparency inside the player's limits", function()
		for _, preset in ipairs(TouchLayoutPresets.All) do
			for _, controlID in ipairs(preset.Layout:GetControlIDs()) do
				local transform = preset.Layout:GetTransform(controlID)
				expect(transform.Scale).toBe(ButtonTransformRules.ClampScale(transform.Scale))
				expect(transform.Transparency).toBe(ButtonTransformRules.ClampTransparency(transform.Transparency))
			end
		end
	end)

	it("finds a preset by id, and nothing for an unknown id", function()
		expect(TouchLayoutPresets.Find("Standard")).toBe(TouchLayoutPresets.All[1])
		expect(TouchLayoutPresets.Find("Nope")).toBeNil()
	end)
end)
