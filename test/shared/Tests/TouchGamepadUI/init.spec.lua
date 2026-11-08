--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TouchGamepadUI = require(ReplicatedStorage.TouchGamepad.UserInterface.TouchGamepadUI)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)

local function makeUI()
	local parent = Instance.new("Folder")
	return TouchGamepadUI.new(parent), parent
end

describe("TouchGamepadUI", function()
	it("offers a root instance for every control the standard layout places", function()
		local ui = makeUI()
		local controls = ui:GetPositionableControls()

		for _, controlID in ipairs(TouchGamepadLayoutRegistry.Standard:GetControlIDs()) do
			expect(controls[controlID]).never.toBeNil()
			expect(controls[controlID]:GetInstance():IsA("GuiObject")).toBe(true)
		end
	end)

	it("offers the pad's frame for the pad and the button itself for a lone button", function()
		local ui = makeUI()
		local controls = ui:GetPositionableControls()

		expect(controls.DPad:GetInstance().Name).toBe("DPad")
		expect(controls.Jump:GetInstance()).toBe(ui:GetButton("Jump"):GetInstance())
	end)

	it("sets the display order of its screen", function()
		local ui, parent = makeUI()

		ui:SetDisplayOrder(5)

		expect(parent.TouchGamepad.DisplayOrder).toBe(5)
	end)
end)
