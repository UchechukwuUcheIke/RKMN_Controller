--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputMapper = require(ReplicatedStorage.PlayerInput.InputMapper)
local DeviceDetector = require(ReplicatedStorage.PlayerInput.DeviceDetector)

-- Stands in for UserInputService, whose last input type can't be driven from a test.
local function makeFakeInputService(startingInputType)
	local service = { lastInputType = startingInputType, LastInputTypeChanged = Signal.new() }
	function service:GetLastInputType()
		return self.lastInputType
	end
	function service:Switch(inputType)
		self.lastInputType = inputType
		self.LastInputTypeChanged:Fire(inputType)
	end
	return service
end

local function makeDetector(startingInputType)
	local service = makeFakeInputService(startingInputType)
	local mapper = InputMapper.new()
	return DeviceDetector.new(service, mapper), service, mapper
end

describe("DeviceDetector", function()
	it("resolves the starting device from the last input type", function()
		expect(makeDetector(Enum.UserInputType.Keyboard):GetCurrentDevice()).toBe("Keyboard")
		expect(makeDetector(Enum.UserInputType.Touch):GetCurrentDevice()).toBe("Touch")
		expect(makeDetector(Enum.UserInputType.Gamepad1):GetCurrentDevice()).toBe("Gamepad")
	end)

	it("treats other input types as keyboard", function()
		expect(makeDetector(Enum.UserInputType.MouseMovement):GetCurrentDevice()).toBe("Keyboard")
	end)

	it("loads the scheme for the starting device", function()
		local _, _, mapper = makeDetector(Enum.UserInputType.Keyboard)
		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBe("Jump")
	end)

	it("swaps the loaded scheme and announces the new device", function()
		local detector, service, mapper = makeDetector(Enum.UserInputType.Keyboard)
		local announced = {}
		detector.OnContextChanged:Connect(function(device)
			table.insert(announced, device)
		end)

		service:Switch(Enum.UserInputType.Gamepad1)

		expect(announced).toEqual({ "Gamepad" })
		expect(mapper:GetActionForKey(Enum.KeyCode.ButtonA)).toBe("Jump")
		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBeNil()
	end)

	it("loads an empty scheme for touch", function()
		local _, service, mapper = makeDetector(Enum.UserInputType.Keyboard)

		service:Switch(Enum.UserInputType.Touch)

		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBeNil()
	end)

	it("does not announce a change within the same device", function()
		local detector, service = makeDetector(Enum.UserInputType.Gamepad1)
		local announced = 0
		detector.OnContextChanged:Connect(function()
			announced += 1
		end)

		service:Switch(Enum.UserInputType.Gamepad2)

		expect(announced).toBe(0)
	end)

	it("stops reacting once destroyed", function()
		local detector, service = makeDetector(Enum.UserInputType.Keyboard)
		local announced = 0
		detector.OnContextChanged:Connect(function()
			announced += 1
		end)

		detector:Destroy()
		service:Switch(Enum.UserInputType.Touch)

		expect(announced).toBe(0)
	end)
end)
