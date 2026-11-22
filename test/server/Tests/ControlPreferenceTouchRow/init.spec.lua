--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlPreferenceTouchRow = require(ServerScriptService.Server.Telemetry.ControlPreferences.ControlPreferenceTouchRow)

local ENTRY = {
	Control = "Jump",
	PositionScaleX = 0.8,
	PositionScaleY = 0.5,
	BaseSizeX = 80,
	BaseSizeY = 90,
	Scale = 1.25,
	Transparency = 0.3,
}

describe("ControlPreferenceTouchRow.new", function()
	it("maps every field onto the table's columns", function()
		local row = ControlPreferenceTouchRow.new(ENTRY, "report-1")

		expect(row.report_id).toBe("report-1")
		expect(row.position_scale_x).toBe(0.8)
		expect(row.position_scale_y).toBe(0.5)
		expect(row.base_size_x).toBe(80)
		expect(row.base_size_y).toBe(90)
		expect(row.scale).toBe(1.25)
		expect(row.transparency).toBe(0.3)
	end)

	it("lowercases the control name", function()
		expect(ControlPreferenceTouchRow.new(ENTRY, "report-1").control).toBe("jump")
	end)

	it("is frozen", function()
		expect(table.isfrozen(ControlPreferenceTouchRow.new(ENTRY, "report-1"))).toBe(true)
	end)
end)
