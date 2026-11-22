--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlPreferenceBindingRow = require(ServerScriptService.Server.Telemetry.ControlPreferences.ControlPreferenceBindingRow)

describe("ControlPreferenceBindingRow.new", function()
	it("attaches the report id and lowercases the action and binding", function()
		local row = ControlPreferenceBindingRow.new({ Action = "Jump", Binding = "Space" }, "report-1")

		expect(row.report_id).toBe("report-1")
		expect(row.action).toBe("jump")
		expect(row.binding).toBe("space")
	end)

	it("is frozen", function()
		local row = ControlPreferenceBindingRow.new({ Action = "Left", Binding = "A" }, "report-1")

		expect(table.isfrozen(row)).toBe(true)
	end)
end)
