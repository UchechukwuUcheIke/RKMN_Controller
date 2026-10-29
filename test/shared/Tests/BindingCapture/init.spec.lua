--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local BindingCapture = require(ReplicatedStorage.PlayerInput.BindingCapture)

-- Stands in for UserInputService, whose input events can't be driven from a test.
local function makeFakeInputService()
	local service = { InputBegan = Signal.new() }
	function service:Press(inputType, keyCode, gameProcessed)
		self.InputBegan:Fire({ UserInputType = inputType, KeyCode = keyCode or Enum.KeyCode.Unknown }, gameProcessed or false)
	end
	return service
end

-- Records every callback result; `results` holds nil captures as the string "cancelled".
local function makeCapture()
	local service = makeFakeInputService()
	local capture = BindingCapture.new(service)
	local results = {}
	local function record(binding)
		table.insert(results, binding or "cancelled")
	end
	return capture, service, results, record
end

describe("BindingCapture", function()
	it("reports the next keyboard key pressed", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)

		expect(results).toEqual({ Enum.KeyCode.J })
	end)

	it("reports a key even when Roblox's GUI already handled it", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J, true)

		expect(results).toEqual({ Enum.KeyCode.J })
	end)

	it("stops listening after the first capture", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)
		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.K)

		expect(results).toEqual({ Enum.KeyCode.J })
		expect(capture:IsCapturing()).toBe(false)
	end)

	it("cancels on Escape without reporting a binding", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.Escape, true)

		expect(results).toEqual({ "cancelled" })
	end)

	it("cancels on Escape while capturing a gamepad button", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Gamepad", record)

		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.Escape)

		expect(results).toEqual({ "cancelled" })
	end)

	it("reports a mouse button only when the GUI did not handle the click", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		service:Press(Enum.UserInputType.MouseButton1, nil, true)
		expect(results).toEqual({})

		service:Press(Enum.UserInputType.MouseButton1, nil, false)
		expect(results).toEqual({ Enum.UserInputType.MouseButton1 })
	end)

	it("ignores gamepad buttons while capturing a keyboard binding", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		service:Press(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)

		expect(results).toEqual({})
		expect(capture:IsCapturing()).toBe(true)
	end)

	it("reports a gamepad button and ignores keyboard keys", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Gamepad", record)

		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)
		expect(results).toEqual({})

		service:Press(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
		expect(results).toEqual({ Enum.KeyCode.ButtonA })
	end)

	it("ignores thumbsticks", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Gamepad", record)

		service:Press(Enum.UserInputType.Gamepad1, Enum.KeyCode.Thumbstick1)
		service:Press(Enum.UserInputType.Gamepad1, Enum.KeyCode.Thumbstick2)

		expect(results).toEqual({})
	end)

	it("ignores touch and mouse movement", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		service:Press(Enum.UserInputType.Touch)
		service:Press(Enum.UserInputType.MouseMovement)

		expect(results).toEqual({})
	end)

	it("cancels a capture already in progress when a new one begins", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		capture:Begin("Gamepad", record)
		service:Press(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonB)

		expect(results).toEqual({ "cancelled", Enum.KeyCode.ButtonB })
	end)

	it("lets the callback start the next capture", function()
		local capture, service = makeCapture()
		local second = {}
		capture:Begin("Keyboard", function()
			capture:Begin("Keyboard", function(binding)
				table.insert(second, binding)
			end)
		end)

		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)
		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.K)

		expect(second).toEqual({ Enum.KeyCode.K })
	end)

	it("reports a cancel through the callback", function()
		local capture, _, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		capture:Cancel()

		expect(results).toEqual({ "cancelled" })
		expect(capture:IsCapturing()).toBe(false)
	end)

	it("does nothing when cancelled with no capture in progress", function()
		local capture, _, results = makeCapture()

		capture:Cancel()

		expect(results).toEqual({})
	end)

	it("errors when asked to capture for touch", function()
		local capture = makeCapture()

		expect(function()
			capture:Begin("Touch", function() end)
		end).toThrow()
	end)

	it("stops reacting once destroyed", function()
		local capture, service, results, record = makeCapture()
		capture:Begin("Keyboard", record)

		capture:Destroy()
		service:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)

		expect(results).toEqual({})
	end)
end)
