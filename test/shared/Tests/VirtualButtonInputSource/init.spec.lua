--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local VirtualButtonInputSource = require(ReplicatedStorage.PlayerInput.VirtualButtonInputSource)

-- Stands in for a GuiButton, whose pointer events can't be driven from a test.
local function makeFakeButton()
	local button = {
		InputBegan = Signal.new(),
		InputEnded = Signal.new(),
		MouseLeave = Signal.new(),
	}
	function button:Press(inputType)
		self.InputBegan:Fire({ UserInputType = inputType or Enum.UserInputType.Touch })
	end
	function button:Release(inputType)
		self.InputEnded:Fire({ UserInputType = inputType or Enum.UserInputType.Touch })
	end
	return button
end

local function makeSource()
	local source = VirtualButtonInputSource.new()
	local events = {}
	source.OnActionPressed:Connect(function(action)
		table.insert(events, "pressed " .. action)
	end)
	source.OnActionReleased:Connect(function(action)
		table.insert(events, "released " .. action)
	end)
	return source, events
end

describe("VirtualButtonInputSource", function()
	it("reports a touch press and release on a bound button", function()
		local source, events = makeSource()
		local button = makeFakeButton()
		source:BindButton("Jump", button)

		button:Press()
		expect(source:IsActionHeld("Jump")).toBe(true)
		button:Release()

		expect(source:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "pressed Jump", "released Jump" })
	end)

	it("accepts a left mouse click as a press", function()
		local source, events = makeSource()
		local button = makeFakeButton()
		source:BindButton("Jump", button)

		button:Press(Enum.UserInputType.MouseButton1)

		expect(events).toEqual({ "pressed Jump" })
	end)

	it("ignores other input types", function()
		local source, events = makeSource()
		local button = makeFakeButton()
		source:BindButton("Jump", button)

		button:Press(Enum.UserInputType.MouseButton2)
		button:Press(Enum.UserInputType.Keyboard)

		expect(events).toEqual({})
		expect(source:IsActionHeld("Jump")).toBe(false)
	end)

	it("releases when the pointer leaves the button mid-hold", function()
		local source, events = makeSource()
		local button = makeFakeButton()
		source:BindButton("Jump", button)

		button:Press()
		button.MouseLeave:Fire()

		expect(source:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "pressed Jump", "released Jump" })
	end)

	it("does not report a repeated press while already held, or a release that was never pressed", function()
		local source, events = makeSource()
		local button = makeFakeButton()
		source:BindButton("Jump", button)

		button.MouseLeave:Fire()
		button:Press()
		button:Press()

		expect(events).toEqual({ "pressed Jump" })
	end)

	it("keeps separate actions on separate buttons", function()
		local source, events = makeSource()
		local jump = makeFakeButton()
		local dash = makeFakeButton()
		source:BindButton("Jump", jump)
		source:BindButton("Dash", dash)

		jump:Press()

		expect(source:IsActionHeld("Jump")).toBe(true)
		expect(source:IsActionHeld("Dash")).toBe(false)
		expect(events).toEqual({ "pressed Jump" })
	end)

	it("ReleaseAll ends every held action", function()
		local source, events = makeSource()
		local jump = makeFakeButton()
		local dash = makeFakeButton()
		source:BindButton("Jump", jump)
		source:BindButton("Dash", dash)

		jump:Press()
		dash:Press()
		table.clear(events)
		source:ReleaseAll()

		expect(source:IsActionHeld("Jump")).toBe(false)
		expect(source:IsActionHeld("Dash")).toBe(false)
		table.sort(events)
		expect(events).toEqual({ "released Dash", "released Jump" })
	end)

	it("stops reporting after Destroy", function()
		local source, events = makeSource()
		local button = makeFakeButton()
		source:BindButton("Jump", button)

		source:Destroy()
		button:Press()

		expect(events).toEqual({})
	end)
end)
