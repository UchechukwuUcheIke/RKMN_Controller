--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Label = require(ReplicatedStorage.ControlCustomization.UIComponents.Label)
local LabelStyle = require(ReplicatedStorage.ControlCustomization.UIComponents.LabelStyle)
local UITheme = require(ReplicatedStorage.ControlCustomization.UIComponents.UITheme)

describe("Label", function()
	it("defaults to a transparent, left-aligned body label", function()
		local textLabel = Label.new({ Text = "Jump" }):GetGuiObject()

		expect(textLabel.Text).toBe("Jump")
		expect(textLabel.BackgroundTransparency).toBe(1)
		expect(textLabel.TextXAlignment).toBe(Enum.TextXAlignment.Left)
		expect(textLabel.Font).toBe(UITheme.Fonts.Body)
		expect(textLabel.TextSize).toBe(UITheme.TextSizes.Body)
	end)

	it("uses the theme's title font, size and color for the Title style", function()
		local textLabel = Label.new({ Style = LabelStyle.Title }):GetGuiObject()

		expect(textLabel.Font).toBe(UITheme.Fonts.Title)
		expect(textLabel.TextSize).toBe(UITheme.TextSizes.Title)
		expect(textLabel.TextColor3).toEqual(UITheme.Colors.TitleText)
	end)

	it("changes its text", function()
		local label = Label.new({ Text = "Unbound" })

		label:SetText("Space, ButtonA")

		expect(label:GetGuiObject().Text).toBe("Space, ButtonA")
	end)
end)
