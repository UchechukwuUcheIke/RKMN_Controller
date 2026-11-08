--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local PresetPicker = require(ReplicatedStorage.ControlCustomization.UIComponents.PresetPicker)

local function makePicker()
	return PresetPicker.new({
		Title = "Presets",
		Options = {
			{ Id = "Standard", Name = "Standard" },
			{ Id = "Compact", Name = "Compact" },
		},
	})
end

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the buttons are wired to.
describe("PresetPicker", function()
	it("shows its title", function()
		local picker = makePicker():GetGuiObject().Picker

		expect(picker.Title.Text).toBe("Presets")
	end)

	it("starts hidden, and shows and hides", function()
		local picker = makePicker()
		expect(picker:IsShown()).toBe(false)

		picker:Show()
		expect(picker:IsShown()).toBe(true)
		expect(picker:GetGuiObject().Visible).toBe(true)

		picker:Hide()
		expect(picker:IsShown()).toBe(false)
	end)

	it("makes a button per option, in the order given", function()
		local list = makePicker():GetGuiObject().Picker.List

		expect(list.Standard.Text).toBe("Standard")
		expect(list.Compact.Text).toBe("Compact")
		expect(list.Standard.LayoutOrder < list.Compact.LayoutOrder).toBe(true)
	end)

	it("scrolls its list so any number of presets fit", function()
		local list = makePicker():GetGuiObject().Picker.List

		expect(list:IsA("ScrollingFrame")).toBe(true)
		expect(list.ScrollingDirection).toBe(Enum.ScrollingDirection.Y)
		expect(list.AutomaticCanvasSize).toBe(Enum.AutomaticSize.Y)
	end)

	it("announces the id of the preset that was pressed", function()
		local picker = makePicker()
		local chosen = {}
		picker.PresetChosen:Connect(function(id)
			table.insert(chosen, id)
		end)

		picker._optionButtons[2]:_handleActivated()

		expect(chosen).toEqual({ "Compact" })
	end)

	it("announces that it was cancelled", function()
		local picker = makePicker()
		local cancelled = 0
		picker.Cancelled:Connect(function()
			cancelled += 1
		end)

		picker._cancelButton:_handleActivated()

		expect(cancelled).toBe(1)
	end)

	it("takes every press while up, so nothing behind it can be touched", function()
		expect(makePicker():GetGuiObject().Active).toBe(true)
	end)
end)
