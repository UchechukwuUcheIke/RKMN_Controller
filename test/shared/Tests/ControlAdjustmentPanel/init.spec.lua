--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlAdjustmentPanel = require(ReplicatedStorage.ControlCustomization.UIComponents.ControlAdjustmentPanel)

local function makeInput()
	return { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new() }
end

local function record(signal)
	local calls = {}
	signal:Connect(function(...)
		table.insert(calls, { ... })
	end)
	return calls
end

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the events are wired to.
describe("ControlAdjustmentPanel", function()
	it("starts by asking for a control, with both sliders switched off", function()
		local panel = ControlAdjustmentPanel.new({})
		local frame = panel:GetGuiObject()

		expect(frame.Title.Text).toBe("Select a control")
		expect(panel._sizeSlider:IsEnabled()).toBe(false)
		expect(panel._opacitySlider:IsEnabled()).toBe(false)
	end)

	it("shows a control's name, size and opacity, and switches the sliders on", function()
		local panel = ControlAdjustmentPanel.new({})
		local frame = panel:GetGuiObject()

		panel:ShowControl("Jump", 1.25, 0.25)

		expect(frame.Title.Text).toBe("Jump")
		expect(frame.SizeLabel.Text).toBe("Size 125%")
		expect(frame.OpacityLabel.Text).toBe("Opacity 75%")
		expect(panel._sizeSlider:GetValue()).toBe(1.25)
		expect(panel._opacitySlider:GetValue()).toBe(0.75)
		expect(panel._sizeSlider:IsEnabled()).toBe(true)
	end)

	it("goes back to asking for a control", function()
		local panel = ControlAdjustmentPanel.new({})
		panel:ShowControl("Jump", 1.25, 0.25)

		panel:ShowNothingSelected()

		expect(panel:GetGuiObject().Title.Text).toBe("Select a control")
		expect(panel:GetGuiObject().SizeLabel.Text).toBe("Size")
		expect(panel._sizeSlider:IsEnabled()).toBe(false)
	end)

	it("does not announce a value just because it was shown", function()
		local panel = ControlAdjustmentPanel.new({})
		local scales = record(panel.ScaleChanged)
		local transparencies = record(panel.TransparencyChanged)

		panel:ShowControl("Jump", 1.25, 0.25)

		expect(#scales).toBe(0)
		expect(#transparencies).toBe(0)
	end)

	it("announces a new size as a scale and updates its label", function()
		local panel = ControlAdjustmentPanel.new({})
		panel:ShowControl("Jump", 1, 0.5)
		local scales = record(panel.ScaleChanged)

		panel._sizeSlider:_setValueFromFraction(1)

		expect(scales).toEqual({ { 1.5 } })
		expect(panel:GetGuiObject().SizeLabel.Text).toBe("Size 150%")
	end)

	it("announces a new opacity as a transparency and updates its label", function()
		local panel = ControlAdjustmentPanel.new({})
		panel:ShowControl("Jump", 1, 0.5)
		local transparencies = record(panel.TransparencyChanged)

		panel._opacitySlider:_setValueFromFraction(1)

		expect(#transparencies).toBe(1)
		expect(transparencies[1][1]).toBeCloseTo(0)
		expect(panel:GetGuiObject().OpacityLabel.Text).toBe("Opacity 100%")
	end)

	it("announces one adjustment however many sliders are being pulled at once", function()
		local panel = ControlAdjustmentPanel.new({})
		panel:ShowControl("Jump", 1, 0.5)
		local started = record(panel.AdjustmentStarted)
		local ended = record(panel.AdjustmentEnded)

		panel._sizeSlider._dragTracker:_handleInputBegan(makeInput())
		panel._opacitySlider._dragTracker:_handleInputBegan(makeInput())
		expect(#started).toBe(1)

		panel._sizeSlider._dragTracker:_handleInputEnded(makeInput())
		expect(#ended).toBe(0)

		panel._opacitySlider._dragTracker:_handleInputEnded(makeInput())
		expect(#ended).toBe(1)
	end)
end)
