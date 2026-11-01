--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Button = require(ReplicatedStorage.ControlCustomization.UIComponents.Button)
local UITheme = require(ReplicatedStorage.ControlCustomization.UIComponents.UITheme)

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the events are wired to.
describe("Button", function()
	it("applies its props to the underlying TextButton", function()
		local button = Button.new({
			Name = "Reset",
			Text = "Reset to defaults",
			Size = UDim2.fromOffset(160, 40),
			LayoutOrder = 3,
		})
		local textButton = button:GetGuiObject()

		expect(textButton.Name).toBe("Reset")
		expect(textButton.Text).toBe("Reset to defaults")
		expect(textButton.Size).toEqual(UDim2.fromOffset(160, 40))
		expect(textButton.LayoutOrder).toBe(3)
	end)

	it("fires Activated while enabled", function()
		local button = Button.new({})
		local fireCount = 0
		button.Activated:Connect(function()
			fireCount += 1
		end)

		button:_handleActivated()

		expect(fireCount).toBe(1)
	end)

	it("does not fire Activated while disabled, and fires again once re-enabled", function()
		local button = Button.new({ Enabled = false })
		local fireCount = 0
		button.Activated:Connect(function()
			fireCount += 1
		end)

		button:_handleActivated()
		expect(fireCount).toBe(0)

		button:Enable()
		button:_handleActivated()
		expect(fireCount).toBe(1)
	end)

	it("changes the background with hover and press, and returns to normal on leaving", function()
		local button = Button.new({})
		local textButton = button:GetGuiObject()
		expect(textButton.BackgroundColor3).toEqual(UITheme.Colors.ButtonNormal)

		button:_handleMouseEntered()
		expect(textButton.BackgroundColor3).toEqual(UITheme.Colors.ButtonHovered)

		button:_handlePressStarted()
		expect(textButton.BackgroundColor3).toEqual(UITheme.Colors.ButtonPressed)

		button:_handleMouseLeft()
		expect(textButton.BackgroundColor3).toEqual(UITheme.Colors.ButtonNormal)
	end)

	it("shows the focus ring only while focused and enabled", function()
		local button = Button.new({})
		local border = button._border

		button:_handleFocusGained()
		expect(border.Color).toEqual(UITheme.Colors.FocusRing)
		expect(border.Thickness).toBe(UITheme.FocusRingThickness)

		button:_handleFocusLost()
		expect(border.Color).toEqual(UITheme.Colors.ButtonBorder)

		button:_handleFocusGained()
		button:Disable()
		expect(border.Color).toEqual(UITheme.Colors.ButtonBorder)
	end)

	it("clears hover and press when disabled, and cannot be selected", function()
		local button = Button.new({})
		local textButton = button:GetGuiObject()
		button:_handleMouseEntered()
		button:_handlePressStarted()

		button:Disable()
		expect(textButton.Selectable).toBe(false)
		expect(textButton.BackgroundColor3).toEqual(UITheme.Colors.ButtonDisabled)
		expect(textButton.TextColor3).toEqual(UITheme.Colors.DisabledText)

		button:Enable()
		expect(textButton.Selectable).toBe(true)
		expect(textButton.BackgroundColor3).toEqual(UITheme.Colors.ButtonNormal)
	end)

	it("hides Roblox's default selection box", function()
		local button = Button.new({})

		expect(button:GetGuiObject().SelectionImageObject).never.toBe(nil)
	end)

	it("destroys its TextButton", function()
		local button = Button.new({})
		local textButton = button:GetGuiObject()

		button:Destroy()

		expect(textButton.Parent).toBe(nil)
		expect(textButton:IsDescendantOf(game)).toBe(false)
	end)
end)
