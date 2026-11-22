--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlPreferenceRow = require(ServerScriptService.Server.Telemetry.ControlPreferences.ControlPreferenceRow)

local CONTEXT = { ReportId = "report-1", PlaceVersion = 7, SessionId = "session-1" }

describe("ControlPreferenceRow.new", function()
	it("maps the device and context onto the table's columns", function()
		local row = ControlPreferenceRow.new("keyboard", CONTEXT)

		expect(row.id).toBe("report-1")
		expect(row.session_id).toBe("session-1")
		expect(row.device).toBe("keyboard")
		expect(row.place_version).toBe(7)
	end)

	it("carries no user identity", function()
		local row = ControlPreferenceRow.new("touch", CONTEXT)

		expect(row.user_id).toBe(nil)
		expect(row.username).toBe(nil)
	end)

	it("is frozen", function()
		expect(table.isfrozen(ControlPreferenceRow.new("gamepad", CONTEXT))).toBe(true)
	end)
end)
