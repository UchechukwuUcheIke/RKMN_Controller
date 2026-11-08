--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Slider = require(ReplicatedStorage.ControlCustomization.UIComponents.Slider)
local UITheme = require(ReplicatedStorage.ControlCustomization.UIComponents.UITheme)

local function makeInput(inputType)
	return { UserInputType = inputType, Position = Vector3.new() }
end

local function recordValues(slider)
	local values = {}
	slider.ValueChanged:Connect(function(value)
		table.insert(values, value)
	end)
	return values
end

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the events are wired to.
-- A GUI that is not on screen has no size, so pointer positions are turned into fractions by hand.
describe("Slider", function()
	it("starts at its minimum unless given a value, and clamps a starting value into range", function()
		expect(Slider.new({ Min = 0.5, Max = 1.5 }):GetValue()).toBe(0.5)
		expect(Slider.new({ Min = 0.5, Max = 1.5, Value = 1 }):GetValue()).toBe(1)
		expect(Slider.new({ Min = 0.5, Max = 1.5, Value = 9 }):GetValue()).toBe(1.5)
	end)

	it("refuses a range with no width", function()
		expect(function()
			Slider.new({ Min = 1, Max = 1 })
		end).toThrow()
	end)

	it("shows its value as the fill's width and the knob's place", function()
		local slider = Slider.new({ Min = 0, Max = 10, Value = 5 })
		local track = slider:GetGuiObject().Track

		expect(track.Fill.Size).toEqual(UDim2.fromScale(0.5, 1))
		expect(track.Knob.Position).toEqual(UDim2.fromScale(0.5, 0.5))
	end)

	it("maps a fraction of the track onto its range", function()
		local slider = Slider.new({ Min = 0.5, Max = 1.5 })

		slider:_setValueFromFraction(0.5)

		expect(slider:GetValue()).toBe(1)
	end)

	it("clamps a fraction outside the track to the ends", function()
		local slider = Slider.new({ Min = 0, Max = 10, Value = 5 })

		slider:_setValueFromFraction(-3)
		expect(slider:GetValue()).toBe(0)

		slider:_setValueFromFraction(4)
		expect(slider:GetValue()).toBe(10)
	end)

	it("snaps to its step", function()
		local slider = Slider.new({ Min = 0, Max = 1, Step = 0.25 })

		slider:_setValueFromFraction(0.4)

		expect(slider:GetValue()).toBe(0.5)
	end)

	it("announces a value that changed, but not one that stayed the same", function()
		local slider = Slider.new({ Min = 0, Max = 10, Value = 5 })
		local values = recordValues(slider)

		slider:_setValueFromFraction(0.5)
		slider:_setValueFromFraction(0.8)

		expect(values).toEqual({ 8 })
	end)

	it("moves without announcing when a value is pushed in with SetValue", function()
		local slider = Slider.new({ Min = 0, Max = 10 })
		local values = recordValues(slider)

		slider:SetValue(7)

		expect(slider:GetValue()).toBe(7)
		expect(slider:GetGuiObject().Track.Fill.Size).toEqual(UDim2.fromScale(0.7, 1))
		expect(#values).toBe(0)
	end)

	it("clamps a value pushed in with SetValue", function()
		local slider = Slider.new({ Min = 0, Max = 10 })

		slider:SetValue(50)

		expect(slider:GetValue()).toBe(10)
	end)

	it("announces the start and end of a drag", function()
		local slider = Slider.new({ Min = 0, Max = 10 })
		local events = {}
		slider.DragStarted:Connect(function()
			table.insert(events, "started")
		end)
		slider.DragEnded:Connect(function()
			table.insert(events, "ended")
		end)

		slider._dragTracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton1))
		expect(slider:IsDragging()).toBe(true)

		slider._dragTracker:_handleInputEnded(makeInput(Enum.UserInputType.MouseButton1))

		expect(slider:IsDragging()).toBe(false)
		expect(events).toEqual({ "started", "ended" })
	end)

	it("cannot be dragged while disabled, and a drag in progress ends when it is disabled", function()
		local slider = Slider.new({ Min = 0, Max = 10, Enabled = false })
		local ended = 0
		slider.DragEnded:Connect(function()
			ended += 1
		end)

		slider._dragTracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton1))
		expect(slider:IsDragging()).toBe(false)

		slider:Enable()
		slider._dragTracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton1))
		expect(slider:IsDragging()).toBe(true)

		slider:Disable()
		expect(slider:IsDragging()).toBe(false)
		expect(ended).toBe(1)
	end)

	it("greys its fill and knob while disabled", function()
		local slider = Slider.new({ Min = 0, Max = 10 })
		local track = slider:GetGuiObject().Track

		slider:Disable()
		expect(track.Fill.BackgroundColor3).toEqual(UITheme.Colors.SliderDisabled)

		slider:Enable()
		expect(track.Fill.BackgroundColor3).toEqual(UITheme.Colors.SliderFill)
	end)
end)
