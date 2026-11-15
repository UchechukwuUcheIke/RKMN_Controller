--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local ControlProfile = require(ReplicatedStorage.PlayerInput.ControlProfile)
local KeyboardSchemes = require(ReplicatedStorage.PlayerInput.KeyboardSchemes)
local GamepadSchemes = require(ReplicatedStorage.PlayerInput.GamepadSchemes)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local TouchLayoutProfile = require(ReplicatedStorage.TouchGamepad.TouchLayoutProfile)
local ControlPreferenceReporter = require(ReplicatedStorage.Telemetry.ControlPreferences.ControlPreferenceReporter)

local STANDARD = TouchGamepadLayoutRegistry.Standard

local function makeFakeScreen()
	local screen = { IsOpenChanged = Signal.new() }
	function screen:Open()
		self.IsOpenChanged:Fire(true)
	end
	function screen:Close()
		self.IsOpenChanged:Fire(false)
	end
	return screen
end

local function makeReporter()
	local controlProfile = ControlProfile.new(KeyboardSchemes.Standard, GamepadSchemes.Standard)
	local layoutProfile = TouchLayoutProfile.new(STANDARD)
	local controlsScreen, touchScreen = makeFakeScreen(), makeFakeScreen()
	local reports = {}

	local reporter = ControlPreferenceReporter.new({
		ControlProfile = controlProfile,
		TouchLayoutProfile = layoutProfile,
		EditingScreens = { controlsScreen, touchScreen },
		Submit = function(report)
			table.insert(reports, report)
		end,
	})

	return reporter, {
		controlProfile = controlProfile,
		layoutProfile = layoutProfile,
		controlsScreen = controlsScreen,
		touchScreen = touchScreen,
		reports = reports,
	}
end

local function hasBinding(report, action, binding)
	for _, entry in ipairs(report.Bindings) do
		if entry.Action == action and entry.Binding == binding then
			return true
		end
	end
	return false
end

describe("ControlPreferenceReporter", function()
	it("sends nothing when a screen closes without anything having been edited", function()
		local _, parts = makeReporter()

		parts.controlsScreen:Open()
		parts.controlsScreen:Close()

		expect(#parts.reports).toBe(0)
	end)

	it("sends nothing while the screen is still open", function()
		local _, parts = makeReporter()

		parts.controlsScreen:Open()
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)

		expect(#parts.reports).toBe(0)
	end)

	it("sends the keyboard scheme as it stands when the player closes the screen", function()
		local _, parts = makeReporter()

		parts.controlsScreen:Open()
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.controlsScreen:Close()

		expect(#parts.reports).toBe(1)
		expect(parts.reports[1].Device).toBe(InputDevice.Keyboard)
		expect(hasBinding(parts.reports[1], "Jump", "J")).toBe(true)
	end)

	it("sends one report for several edits, holding only the last state", function()
		local _, parts = makeReporter()

		parts.controlsScreen:Open()
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.K)
		parts.controlProfile:UnbindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.controlsScreen:Close()

		expect(#parts.reports).toBe(1)
		expect(hasBinding(parts.reports[1], "Jump", "K")).toBe(true)
		expect(hasBinding(parts.reports[1], "Jump", "J")).toBe(false)
	end)

	it("sends a report for each device that was edited", function()
		local _, parts = makeReporter()

		parts.controlsScreen:Open()
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.controlProfile:BindKey(InputDevice.Gamepad, "Jump", Enum.KeyCode.ButtonB)
		parts.controlsScreen:Close()

		expect(#parts.reports).toBe(2)
	end)

	it("sends a reset device's scheme, which is back to the default", function()
		local _, parts = makeReporter()

		parts.controlsScreen:Open()
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.controlProfile:ResetDevice(InputDevice.Keyboard)
		parts.controlsScreen:Close()

		expect(#parts.reports).toBe(1)
		expect(hasBinding(parts.reports[1], "Jump", "J")).toBe(false)
	end)

	it("sends the touch layout when the touch editor closes after a save", function()
		local _, parts = makeReporter()
		local moved = STANDARD:CopyWithTransform(
			"Jump",
			STANDARD:GetTransform("Jump"):CopyWithChanges({ Position = UDim2.fromScale(0.5, 0.25) })
		)

		parts.touchScreen:Open()
		parts.layoutProfile:SetLayout(moved)
		parts.touchScreen:Close()

		expect(#parts.reports).toBe(1)
		expect(parts.reports[1].Device).toBe(InputDevice.Touch)
		expect(#parts.reports[1].TouchControls).toBe(#STANDARD:GetControlIDs())
	end)

	it("sends nothing from the touch editor when no layout was saved", function()
		local _, parts = makeReporter()

		parts.touchScreen:Open()
		parts.touchScreen:Close()

		expect(#parts.reports).toBe(0)
	end)

	it("does not send the same edits again on the next close", function()
		local _, parts = makeReporter()

		parts.controlsScreen:Open()
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.controlsScreen:Close()
		parts.controlsScreen:Open()
		parts.controlsScreen:Close()

		expect(#parts.reports).toBe(1)
	end)

	it("sends whatever was edited when either screen closes", function()
		local _, parts = makeReporter()

		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.touchScreen:Close()

		expect(#parts.reports).toBe(1)
	end)

	it("stops reacting once destroyed", function()
		local reporter, parts = makeReporter()

		reporter:Destroy()
		parts.controlProfile:BindKey(InputDevice.Keyboard, "Jump", Enum.KeyCode.J)
		parts.controlsScreen:Close()

		expect(#parts.reports).toBe(0)
	end)
end)
