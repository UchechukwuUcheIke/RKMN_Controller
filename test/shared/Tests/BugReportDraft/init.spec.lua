--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local BugReportDraft = require(ReplicatedStorage.Telemetry.BugReport.BugReportDraft)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local InputPhase = require(ReplicatedStorage.Telemetry.InputActionLog.InputPhase)
local InputActionLogEntry = require(ReplicatedStorage.Telemetry.InputActionLog.InputActionLogEntry)

describe("BugReportDraft.new", function()
	local function makeLog()
		return { InputActionLogEntry.new(InputAction.Jump, InputPhase.Began, 1) }
	end

	it("sets every field", function()
		local log = makeLog()
		local draft = BugReportDraft.new("It broke", "pc", "keyboard", log)

		expect(draft.Description).toBe("It broke")
		expect(draft.Platform).toBe("pc")
		expect(draft.InputDevice).toBe("keyboard")
		expect(draft.InputLog).toBe(log)
	end)

	it("returns a frozen table", function()
		expect(table.isfrozen(BugReportDraft.new("It broke", "pc", "keyboard", makeLog()))).toBe(true)
	end)

	it("returns a plain table with no metatable, so it can cross the network", function()
		expect(getmetatable(BugReportDraft.new("It broke", "pc", "keyboard", makeLog()))).toBe(nil)
	end)
end)
