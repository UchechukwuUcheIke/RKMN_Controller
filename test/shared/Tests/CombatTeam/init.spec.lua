--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Team = require(ReplicatedStorage.Combat.Team)

describe("Team.canHurt", function()
	it("lets the player hurt enemies and destructibles", function()
		expect(Team.canHurt(Team.Player, Team.Enemy)).toBe(true)
		expect(Team.canHurt(Team.Player, Team.Neutral)).toBe(true)
	end)

	it("does not let the player hurt the player", function()
		expect(Team.canHurt(Team.Player, Team.Player)).toBe(false)
	end)

	it("lets enemies hurt the player but not each other", function()
		expect(Team.canHurt(Team.Enemy, Team.Player)).toBe(true)
		expect(Team.canHurt(Team.Enemy, Team.Enemy)).toBe(false)
	end)

	it("lets hazards hurt both the player and enemies", function()
		expect(Team.canHurt(Team.Hazard, Team.Player)).toBe(true)
		expect(Team.canHurt(Team.Hazard, Team.Enemy)).toBe(true)
	end)

	it("never lets neutral objects hurt anyone", function()
		expect(Team.canHurt(Team.Neutral, Team.Player)).toBe(false)
		expect(Team.canHurt(Team.Neutral, Team.Enemy)).toBe(false)
	end)
end)
