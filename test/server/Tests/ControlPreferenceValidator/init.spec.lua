--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlPreferenceReportContext = require(ServerScriptService.Server.Telemetry.ControlPreferences.ControlPreferenceReportContext)
local ControlPreferenceValidator = require(ServerScriptService.Server.Telemetry.ControlPreferences.ControlPreferenceValidator)

local CONTEXT = ControlPreferenceReportContext.new("report-1", 3, "session-1")

local function touchEntry(overrides)
	local entry = {
		Control = "Jump",
		PositionScaleX = 0.8,
		PositionScaleY = 0.5,
		BaseSizeX = 80,
		BaseSizeY = 80,
		Scale = 1,
		Transparency = 0.2,
	}
	for key, value in overrides or {} do
		entry[key] = value
	end
	return entry
end

local function keyboardReport(bindings)
	return { Device = "keyboard", Bindings = bindings, TouchControls = {} }
end

local function touchReport(controls)
	return { Device = "touch", Bindings = {}, TouchControls = controls }
end

describe("ControlPreferenceValidator.Validate: whole report", function()
	it("rejects a report that is not a table", function()
		expect(ControlPreferenceValidator.Validate("nope", CONTEXT).Ok).toBe(false)
	end)

	it("rejects an unknown device", function()
		expect(ControlPreferenceValidator.Validate({ Device = "toaster" }, CONTEXT).Ok).toBe(false)
		expect(ControlPreferenceValidator.Validate({ Device = "unknown" }, CONTEXT).Ok).toBe(false)
		expect(ControlPreferenceValidator.Validate({}, CONTEXT).Ok).toBe(false)
	end)

	it("rejects a report with nothing valid in it", function()
		local result = ControlPreferenceValidator.Validate(keyboardReport({}), CONTEXT)

		expect(result.Ok).toBe(false)
		expect(result.Reason).toBe("Report has no valid entries")
	end)

	it("builds the report row from the context", function()
		local result = ControlPreferenceValidator.Validate(keyboardReport({ { Action = "Jump", Binding = "Space" } }), CONTEXT)

		expect(result.Ok).toBe(true)
		expect(result.Row.id).toBe("report-1")
		expect(result.Row.session_id).toBe("session-1")
		expect(result.Row.device).toBe("keyboard")
		expect(result.Row.place_version).toBe(3)
	end)
end)

describe("ControlPreferenceValidator.Validate: bindings", function()
	it("turns each binding into a row tied to the report", function()
		local result = ControlPreferenceValidator.Validate(
			keyboardReport({ { Action = "Jump", Binding = "Space" }, { Action = "Left", Binding = "A" } }),
			CONTEXT
		)

		expect(#result.BindingRows).toBe(2)
		expect(result.BindingRows[1].report_id).toBe("report-1")
		expect(result.BindingRows[1].action).toBe("jump")
		expect(#result.TouchRows).toBe(0)
	end)

	it("drops entries with an unknown action or a malformed binding", function()
		local result = ControlPreferenceValidator.Validate(
			keyboardReport({
				{ Action = "Fly", Binding = "Space" },
				{ Action = "Jump", Binding = "Space; drop table" },
				{ Action = "Jump", Binding = 5 },
				"junk",
				{ Action = "Dash", Binding = "LeftShift" },
			}),
			CONTEXT
		)

		expect(#result.BindingRows).toBe(1)
		expect(result.BindingRows[1].action).toBe("dash")
	end)

	it("drops repeats, ignoring case", function()
		local result = ControlPreferenceValidator.Validate(
			keyboardReport({ { Action = "Jump", Binding = "Space" }, { Action = "Jump", Binding = "SPACE" } }),
			CONTEXT
		)

		expect(#result.BindingRows).toBe(1)
	end)

	it("keeps no more than the cap", function()
		local bindings = {}
		for index = 1, ControlPreferenceValidator.MAX_BINDING_ENTRIES + 20 do
			table.insert(bindings, { Action = "Jump", Binding = "Key" .. index })
		end

		local result = ControlPreferenceValidator.Validate(keyboardReport(bindings), CONTEXT)

		expect(#result.BindingRows).toBe(ControlPreferenceValidator.MAX_BINDING_ENTRIES)
	end)

	it("ignores touch controls on a keyboard report", function()
		local report = keyboardReport({ { Action = "Jump", Binding = "Space" } })
		report.TouchControls = { touchEntry() }

		expect(#ControlPreferenceValidator.Validate(report, CONTEXT).TouchRows).toBe(0)
	end)
end)

describe("ControlPreferenceValidator.Validate: touch controls", function()
	it("turns each control into a row tied to the report", function()
		local result = ControlPreferenceValidator.Validate(touchReport({ touchEntry(), touchEntry({ Control = "DPad" }) }), CONTEXT)

		expect(result.Ok).toBe(true)
		expect(#result.TouchRows).toBe(2)
		expect(result.TouchRows[1].report_id).toBe("report-1")
		expect(result.TouchRows[2].control).toBe("dpad")
		expect(#result.BindingRows).toBe(0)
	end)

	it("drops controls that do not exist", function()
		local result = ControlPreferenceValidator.Validate(
			touchReport({ touchEntry({ Control = "Teleport" }), touchEntry() }),
			CONTEXT
		)

		expect(#result.TouchRows).toBe(1)
	end)

	it("drops controls with numbers outside the allowed ranges", function()
		local result = ControlPreferenceValidator.Validate(
			touchReport({
				touchEntry({ Control = "Left", PositionScaleX = 3 }),
				touchEntry({ Control = "Right", BaseSizeY = -1 }),
				touchEntry({ Control = "Dash", Scale = 11 }),
				touchEntry({ Control = "Shoot", Transparency = 1.5 }),
				touchEntry({ Control = "Menu" }),
			}),
			CONTEXT
		)

		expect(#result.TouchRows).toBe(1)
		expect(result.TouchRows[1].control).toBe("menu")
	end)

	it("drops controls with NaN, infinite or non-number values", function()
		local result = ControlPreferenceValidator.Validate(
			touchReport({
				touchEntry({ Control = "Left", Scale = 0 / 0 }),
				touchEntry({ Control = "Right", BaseSizeX = math.huge }),
				touchEntry({ Control = "Dash", Transparency = "0.5" }),
			}),
			CONTEXT
		)

		expect(result.Ok).toBe(false)
	end)

	it("drops repeats of the same control", function()
		local result = ControlPreferenceValidator.Validate(touchReport({ touchEntry(), touchEntry() }), CONTEXT)

		expect(#result.TouchRows).toBe(1)
	end)

	it("ignores bindings on a touch report", function()
		local report = touchReport({ touchEntry() })
		report.Bindings = { { Action = "Jump", Binding = "Space" } }

		expect(#ControlPreferenceValidator.Validate(report, CONTEXT).BindingRows).toBe(0)
	end)
end)
