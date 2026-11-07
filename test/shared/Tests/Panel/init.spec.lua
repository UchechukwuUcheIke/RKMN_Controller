--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Panel = require(ReplicatedStorage.ControlCustomization.UIComponents.Panel)
local PanelTone = require(ReplicatedStorage.ControlCustomization.UIComponents.PanelTone)
local UITheme = require(ReplicatedStorage.ControlCustomization.UIComponents.UITheme)

describe("Panel", function()
	it("defaults to the Window tone, filling its parent and visible", function()
		local frame = Panel.new({}):GetGuiObject()

		expect(frame.BackgroundColor3).toEqual(UITheme.Colors.Window)
		expect(frame.Size).toEqual(UDim2.fromScale(1, 1))
		expect(frame.Visible).toBe(true)
	end)

	it("can start hidden", function()
		local frame = Panel.new({ Visible = false }):GetGuiObject()

		expect(frame.Visible).toBe(false)
	end)

	it("rounds its corners by tone", function()
		local windowCorner = Panel.new({ Tone = PanelTone.Window }):GetGuiObject():FindFirstChildOfClass("UICorner")
		local rowCorner = Panel.new({ Tone = PanelTone.Row }):GetGuiObject():FindFirstChildOfClass("UICorner")

		expect(windowCorner.CornerRadius).toEqual(UITheme.WindowCornerRadius)
		expect(rowCorner.CornerRadius).toEqual(UITheme.RowCornerRadius)
	end)

	it("changes color when its tone changes", function()
		local panel = Panel.new({ Tone = PanelTone.Row })

		panel:SetTone(PanelTone.RowHighlighted)

		expect(panel:GetGuiObject().BackgroundColor3).toEqual(UITheme.Colors.RowHighlighted)
	end)

	it("shows and hides", function()
		local panel = Panel.new({})

		panel:SetVisible(false)

		expect(panel:GetGuiObject().Visible).toBe(false)
	end)
end)
