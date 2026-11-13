--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputMapper = require(ReplicatedStorage.PlayerInput.InputMapper)
local HardwareInputSource = require(ReplicatedStorage.PlayerInput.HardwareInputSource)
local VirtualButtonInputSource = require(ReplicatedStorage.PlayerInput.VirtualButtonInputSource)
local InputActionMerger = require(ReplicatedStorage.PlayerInput.InputActionMerger)

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

local function makeFakeButton()
	local button = {
		InputBegan = Signal.new(),
		InputEnded = Signal.new(),
		MouseLeave = Signal.new(),
	}
	function button:Press()
		self.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch })
	end
	function button:Release()
		self.InputEnded:Fire({ UserInputType = Enum.UserInputType.Touch })
	end
	return button
end

local function makeObserver()
	local mapper = InputMapper.new()
	mapper:LoadControlScheme({
		Jump = { [Enum.KeyCode.Space] = true },
		Dash = { [Enum.KeyCode.LeftShift] = true },
	})
	local service = makeFakeInputService()
	local observer = InputActionMerger.new(HardwareInputSource.new(mapper, service), VirtualButtonInputSource.new())
	local button = makeFakeButton()
	observer:BindVirtualButton("Jump", button)

	local events = {}
	observer.OnActionBegan:Connect(function(action)
		table.insert(events, "began " .. action)
	end)
	observer.OnActionEnded:Connect(function(action)
		table.insert(events, "ended " .. action)
	end)
	return observer, service, button, events
end

describe("InputActionMerger", function()
	it("begins and ends an action held on the keyboard", function()
		local observer, service, _, events = makeObserver()

		service:Press(Enum.KeyCode.Space)
		expect(observer:IsActionHeld("Jump")).toBe(true)
		service:Release(Enum.KeyCode.Space)

		expect(observer:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "began Jump", "ended Jump" })
	end)

	it("begins and ends an action held on an on-screen button", function()
		local observer, _, button, events = makeObserver()

		button:Press()
		expect(observer:IsActionHeld("Jump")).toBe(true)
		button:Release()

		expect(observer:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "began Jump", "ended Jump" })
	end)

	it("treats a key and a button held together as one hold that begins once", function()
		local _, service, button, events = makeObserver()

		service:Press(Enum.KeyCode.Space)
		button:Press()

		expect(events).toEqual({ "began Jump" })
	end)

	it("keeps the action held until the last of the key and the button lets go", function()
		local observer, service, button, events = makeObserver()

		service:Press(Enum.KeyCode.Space)
		button:Press()
		service:Release(Enum.KeyCode.Space)
		expect(observer:IsActionHeld("Jump")).toBe(true)
		button:Release()

		expect(observer:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "began Jump", "ended Jump" })
	end)

	it("does not end the action on window focus loss while a button still holds it", function()
		local observer, service, button, events = makeObserver()

		service:Press(Enum.KeyCode.Space)
		button:Press()
		service.WindowFocusReleased:Fire()

		expect(observer:IsActionHeld("Jump")).toBe(true)
		expect(events).toEqual({ "began Jump" })
	end)

	it("ends the action on window focus loss when only the keyboard held it", function()
		local observer, service, _, events = makeObserver()

		service:Press(Enum.KeyCode.Space)
		service.WindowFocusReleased:Fire()

		expect(observer:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({ "began Jump", "ended Jump" })
	end)

	it("ReleaseAllVirtual ends a button hold but not a keyboard one", function()
		local observer, service, button, events = makeObserver()

		button:Press()
		service:Press(Enum.KeyCode.LeftShift)
		table.clear(events)
		observer:ReleaseAllVirtual()

		expect(observer:IsActionHeld("Jump")).toBe(false)
		expect(observer:IsActionHeld("Dash")).toBe(true)
		expect(events).toEqual({ "ended Jump" })
	end)

	it("does not report a press Roblox's GUI already handled as held", function()
		local observer, service, _, events = makeObserver()

		service:Press(Enum.KeyCode.Space, true)

		expect(observer:IsActionHeld("Jump")).toBe(false)
		expect(events).toEqual({})
	end)

	it("stops reporting after Destroy", function()
		local observer, service, button, events = makeObserver()

		observer:Destroy()
		service:Press(Enum.KeyCode.Space)
		button:Press()

		expect(events).toEqual({})
	end)
end)
