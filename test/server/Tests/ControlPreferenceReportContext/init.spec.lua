--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlPreferenceReportContext = require(ServerScriptService.Server.Telemetry.ControlPreferences.ControlPreferenceReportContext)

describe("ControlPreferenceReportContext.new", function()
	it("holds the report id, place version and session id", function()
		local context = ControlPreferenceReportContext.new("report-1", 7, "session-1")

		expect(context.ReportId).toBe("report-1")
		expect(context.PlaceVersion).toBe(7)
		expect(context.SessionId).toBe("session-1")
	end)

	it("is frozen", function()
		expect(table.isfrozen(ControlPreferenceReportContext.new("report-1", 7, "session-1"))).toBe(true)
	end)
end)
