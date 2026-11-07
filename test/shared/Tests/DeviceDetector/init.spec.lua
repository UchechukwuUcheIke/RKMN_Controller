--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputMapper = require(ReplicatedStorage.PlayerInput.InputMapper)
local DeviceDetector = require(ReplicatedStorage.PlayerInput.DeviceDetector)
local ControlProfile = require(ReplicatedStorage.PlayerInput.ControlProfile)
local KeyboardSchemes = require(ReplicatedStorage.PlayerInput.KeyboardSchemes)
local GamepadSchemes = require(ReplicatedStorage.PlayerInput.GamepadSchemes)

-- Stands in for UserInputService, whose preferred input can't be driven from a test.
local function makeFakeInputService(startingPreferredInput)
	local service = { PreferredInput = startingPreferredInput, preferredInputChanged = Signal.new() }
	function service:GetPropertyChangedSignal(propertyName)
		assert(propertyName == "PreferredInput", "the detector should only watch PreferredInput")
		return self.preferredInputChanged
	end
	function service:Switch(preferredInput)
		self.PreferredInput = preferredInput
		self.preferredInputChanged:Fire()
	end
	return service
end

local function makeDetector(startingPreferredInput)
	local service = makeFakeInputService(startingPreferredInput)
	local mapper = InputMapper.new()
	local profile = ControlProfile.new(KeyboardSchemes.Standard, GamepadSchemes.Standard)
	return DeviceDetector.new(service, mapper, profile), service, mapper, profile
end

describe("DeviceDetector", function()
	it("resolves the starting device from the preferred input", function()
		expect(makeDetector(Enum.PreferredInput.KeyboardAndMouse):GetCurrentDevice()).toBe("Keyboard")
		expect(makeDetector(Enum.PreferredInput.Touch):GetCurrentDevice()).toBe("Touch")
		expect(makeDetector(Enum.PreferredInput.Gamepad):GetCurrentDevice()).toBe("Gamepad")
	end)

	it("loads the scheme for the starting device", function()
		local _, _, mapper = makeDetector(Enum.PreferredInput.KeyboardAndMouse)
		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBe("Jump")
	end)

	it("swaps the loaded scheme and announces the new device", function()
		local detector, service, mapper = makeDetector(Enum.PreferredInput.KeyboardAndMouse)
		local announced = {}
		detector.OnContextChanged:Connect(function(device)
			table.insert(announced, device)
		end)

		service:Switch(Enum.PreferredInput.Gamepad)

		expect(announced).toEqual({ "Gamepad" })
		expect(mapper:GetActionForKey(Enum.KeyCode.ButtonA)).toBe("Jump")
		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBeNil()
	end)

	it("loads an empty scheme for touch", function()
		local _, service, mapper = makeDetector(Enum.PreferredInput.KeyboardAndMouse)

		service:Switch(Enum.PreferredInput.Touch)

		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBeNil()
	end)

	it("does not announce a change within the same device", function()
		local detector, service = makeDetector(Enum.PreferredInput.Gamepad)
		local announced = 0
		detector.OnContextChanged:Connect(function()
			announced += 1
		end)

		service:Switch(Enum.PreferredInput.Gamepad)

		expect(announced).toBe(0)
	end)

	it("loads the player's edited scheme for the device in use", function()
		local _, service, mapper, profile = makeDetector(Enum.PreferredInput.KeyboardAndMouse)
		profile:BindKey("Keyboard", "Jump", Enum.KeyCode.J)

		expect(mapper:GetActionForKey(Enum.KeyCode.J)).toBe("Jump")

		service:Switch(Enum.PreferredInput.Gamepad)
		service:Switch(Enum.PreferredInput.KeyboardAndMouse)

		expect(mapper:GetActionForKey(Enum.KeyCode.J)).toBe("Jump")
	end)

	it("applies an edit to the device in use straight away", function()
		local _, _, mapper, profile = makeDetector(Enum.PreferredInput.Gamepad)

		profile:BindKey("Gamepad", "Jump", Enum.KeyCode.ButtonY)

		expect(mapper:GetActionForKey(Enum.KeyCode.ButtonY)).toBe("Jump")
	end)

	it("leaves the mapper alone when a different device is edited", function()
		local _, _, mapper, profile = makeDetector(Enum.PreferredInput.KeyboardAndMouse)

		profile:BindKey("Gamepad", "Jump", Enum.KeyCode.ButtonY)

		expect(mapper:GetActionForKey(Enum.KeyCode.ButtonY)).toBeNil()
	end)

	it("stops reacting once destroyed", function()
		local detector, service = makeDetector(Enum.PreferredInput.KeyboardAndMouse)
		local announced = 0
		detector.OnContextChanged:Connect(function()
			announced += 1
		end)

		detector:Destroy()
		service:Switch(Enum.PreferredInput.Touch)

		expect(announced).toBe(0)
	end)
end)
