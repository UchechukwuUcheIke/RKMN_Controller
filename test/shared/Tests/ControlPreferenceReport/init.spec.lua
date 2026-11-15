--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local KeyboardSchemes = require(ReplicatedStorage.PlayerInput.KeyboardSchemes)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local ControlPreferenceReport = require(ReplicatedStorage.Telemetry.ControlPreferences.ControlPreferenceReport)

local STANDARD = TouchGamepadLayoutRegistry.Standard

local function findBinding(report, action, binding)
	for _, entry in ipairs(report.Bindings) do
		if entry.Action == action and entry.Binding == binding then
			return entry
		end
	end
	return nil
end

local function findControl(report, control)
	for _, entry in ipairs(report.TouchControls) do
		if entry.Control == control then
			return entry
		end
	end
	return nil
end

describe("ControlPreferenceReport", function()
	describe("FromInputScheme", function()
		it("lists every bound input under its action, by the input's name", function()
			local report = ControlPreferenceReport.FromInputScheme(InputDevice.Keyboard, {
				Jump = { [Enum.KeyCode.Space] = true },
				Shoot = { [Enum.UserInputType.MouseButton1] = true },
			})

			expect(report.Device).toBe(InputDevice.Keyboard)
			expect(#report.Bindings).toBe(2)
			expect(findBinding(report, "Jump", "Space")).never.toBeNil()
			expect(findBinding(report, "Shoot", "MouseButton1")).never.toBeNil()
			expect(#report.TouchControls).toBe(0)
		end)

		it("lists each of an action's bindings separately", function()
			local report = ControlPreferenceReport.FromInputScheme(InputDevice.Keyboard, {
				Jump = { [Enum.KeyCode.Space] = true, [Enum.KeyCode.W] = true },
			})

			expect(#report.Bindings).toBe(2)
		end)

		it("skips an input that is marked unbound", function()
			local report = ControlPreferenceReport.FromInputScheme(InputDevice.Keyboard, {
				Jump = { [Enum.KeyCode.Space] = true, [Enum.KeyCode.W] = false },
			})

			expect(#report.Bindings).toBe(1)
		end)

		it("produces the same order however the scheme was built", function()
			local report = ControlPreferenceReport.FromInputScheme(InputDevice.Keyboard, {
				Shoot = { [Enum.KeyCode.X] = true },
				Jump = { [Enum.KeyCode.W] = true, [Enum.KeyCode.Space] = true },
			})

			expect(report.Bindings[1].Action).toBe("Jump")
			expect(report.Bindings[1].Binding).toBe("Space")
			expect(report.Bindings[2].Binding).toBe("W")
			expect(report.Bindings[3].Action).toBe("Shoot")
		end)

		it("reports the standard keyboard scheme in full", function()
			local report = ControlPreferenceReport.FromInputScheme(InputDevice.Keyboard, KeyboardSchemes.Standard)

			expect(findBinding(report, "Menu", "M")).never.toBeNil()
		end)

		it("refuses a touch device, whose controls are a layout", function()
			expect(function()
				ControlPreferenceReport.FromInputScheme(InputDevice.Touch, {})
			end).toThrow()
		end)

		it("is frozen", function()
			local report = ControlPreferenceReport.FromInputScheme(InputDevice.Keyboard, {})

			expect(table.isfrozen(report)).toBe(true)
			expect(table.isfrozen(report.Bindings)).toBe(true)
		end)
	end)

	describe("FromTouchLayout", function()
		it("lists every control in the layout", function()
			local report = ControlPreferenceReport.FromTouchLayout(STANDARD)

			expect(report.Device).toBe(InputDevice.Touch)
			expect(#report.TouchControls).toBe(#STANDARD:GetControlIDs())
			expect(#report.Bindings).toBe(0)
		end)

		it("carries each control's position, base size, scale and transparency", function()
			local report = ControlPreferenceReport.FromTouchLayout(STANDARD)
			local jump = STANDARD:GetTransform("Jump")
			local entry = findControl(report, "Jump")

			expect(entry.PositionScaleX).toBe(jump.Position.X.Scale)
			expect(entry.PositionScaleY).toBe(jump.Position.Y.Scale)
			expect(entry.BaseSizeX).toBe(jump.BaseSize.X.Offset)
			expect(entry.BaseSizeY).toBe(jump.BaseSize.Y.Offset)
			expect(entry.Scale).toBe(jump.Scale)
			expect(entry.Transparency).toBe(jump.Transparency)
		end)

		it("reflects an edited control", function()
			local moved = STANDARD:CopyWithTransform(
				"Jump",
				STANDARD:GetTransform("Jump"):CopyWithChanges({ Position = UDim2.fromScale(0.5, 0.25), Scale = 1.5 })
			)

			local entry = findControl(ControlPreferenceReport.FromTouchLayout(moved), "Jump")

			expect(entry.PositionScaleX).toBe(0.5)
			expect(entry.PositionScaleY).toBe(0.25)
			expect(entry.Scale).toBe(1.5)
		end)

		it("lists controls in a stable order", function()
			local report = ControlPreferenceReport.FromTouchLayout(STANDARD)

			for index = 2, #report.TouchControls do
				expect(report.TouchControls[index - 1].Control < report.TouchControls[index].Control).toBe(true)
			end
		end)
	end)
end)
