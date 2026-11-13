--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputMapper = require(ReplicatedStorage.PlayerInput.InputMapper)
local HardwareInputSource = require(ReplicatedStorage.PlayerInput.HardwareInputSource)

-- Stands in for UserInputService, whose input events can't be driven from a test.
local function makeFakeInputService()
	local service = {
		InputBegan = Signal.new(),
		InputEnded = Signal.new(),
		WindowFocusReleased = Signal.new(),
	}
	local function makeInput(keyCode)
		return { UserInputType = Enum.UserInputType.Keyboard, KeyCode = keyCode }
	end
	function service:Press(keyCode, gameProcessed)
		self.InputBegan:Fire(makeInput(keyCode), gameProcessed or false)
	end
	function service:Release(keyCode)
		self.InputEnded:Fire(makeInput(keyCode), false)
	end
	return service
end

local function makeSource()
	local mapper = InputMapper.new()
	mapper:LoadControlScheme({
		Jump = { [Enum.KeyCode.Space] = true, [Enum.KeyCode.W] = true },
		Dash = { [Enum.KeyCode.LeftShift] = true },
	})
	local service = makeFakeInputService()
	local source = HardwareInputSource.new(mapper, service)

	local events = {}
	source.OnActionPressed:Connect(function(action)
		table.insert(events, "pressed " .. action)
	end)
	source.OnActionReleased:Connect(function(action)
		table.insert(events, "released " .. action)
	end)
	return source, service, events
end

describe("HardwareInputSource", function()
	it("reports a mapped key press and release", function()
		local source, service, events = makeSource()

		service:Press(Enum.KeyCode.Space)
		expect(source:IsActionHeld("Jump")).toBe(true)
		service:Release(Enum.KeyCode.Space)

		expect(source:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "pressed Jump", "released Jump" })
	end)

	it("ignores keys that are not mapped", function()
		local source, service, events = makeSource()

		service:Press(Enum.KeyCode.Q)
		service:Release(Enum.KeyCode.Q)

		expect(events).toEqual({})
		expect(source:IsActionHeld("Jump")).toBe(false)
	end)

	it("ignores a press Roblox's GUI already handled, and its release", function()
		local source, service, events = makeSource()

		service:Press(Enum.KeyCode.Space, true)
		service:Release(Enum.KeyCode.Space)

		expect(events).toEqual({})
		expect(source:IsActionHeld("Jump")).toBe(false)
	end)

	it("still ends a hold whose release was handled by the GUI", function()
		local _, service, events = makeSource()

		service:Press(Enum.KeyCode.Space)
		service.InputEnded:Fire({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Space }, true)

		expect(events).toEqual({ "pressed Jump", "released Jump" })
	end)

	it("keeps an action held until every binding of it is released", function()
		local source, service, events = makeSource()

		service:Press(Enum.KeyCode.Space)
		service:Press(Enum.KeyCode.W)
		service:Release(Enum.KeyCode.Space)
		expect(source:IsActionHeld("Jump")).toBe(true)
		service:Release(Enum.KeyCode.W)

		expect(source:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "pressed Jump", "released Jump" })
	end)

	it("releases every held action when the window loses focus", function()
		local source, service, events = makeSource()

		service:Press(Enum.KeyCode.Space)
		service:Press(Enum.KeyCode.W)
		service:Press(Enum.KeyCode.LeftShift)
		table.clear(events)
		service.WindowFocusReleased:Fire()

		expect(source:IsActionHeld("Jump")).toBe(false)
		expect(source:IsActionHeld("Dash")).toBe(false)
		table.sort(events)
		expect(events).toEqual({ "released Dash", "released Jump" })
	end)

	it("does nothing on focus loss when nothing is held", function()
		local _, service, events = makeSource()

		service.WindowFocusReleased:Fire()

		expect(events).toEqual({})
	end)

	it("stops reporting after Destroy", function()
		local source, service, events = makeSource()

		source:Destroy()
		service:Press(Enum.KeyCode.Space)

		expect(events).toEqual({})
	end)
end)
