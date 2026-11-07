--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local AppBar = require(ReplicatedStorage.ControlCustomization.UIComponents.AppBar)
local UITheme = require(ReplicatedStorage.ControlCustomization.UIComponents.UITheme)

describe("AppBar", function()
	it("shows its title on a bar-toned background", function()
		local frame = AppBar.new({ Title = "Keyboard controls" }):GetGuiObject()

		expect(frame.Title.Text).toBe("Keyboard controls")
		expect(frame.BackgroundColor3).toEqual(UITheme.Colors.AppBar)
	end)

	it("changes its title", function()
		local appBar = AppBar.new({ Title = "Keyboard controls" })

		appBar:SetTitle("Gamepad controls")

		expect(appBar:GetGuiObject().Title.Text).toBe("Gamepad controls")
	end)

	it("holds added actions in the order they were added", function()
		local appBar = AppBar.new({})
		local first = Instance.new("Frame")
		local second = Instance.new("Frame")

		appBar:AddAction(first)
		appBar:AddAction(second)

		expect(first.Parent).toBe(appBar:GetGuiObject().Actions)
		expect(second.Parent).toBe(appBar:GetGuiObject().Actions)
		expect(first.LayoutOrder < second.LayoutOrder).toBe(true)
	end)
end)
