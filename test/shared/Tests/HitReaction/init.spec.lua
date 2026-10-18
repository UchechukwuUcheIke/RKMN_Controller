--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local HitReaction = require(ReplicatedStorage.Combat.Hitbox.HitReaction)

describe("HitReaction", function()
	it("is frozen", function()
		expect(table.isfrozen(HitReaction)).toBe(true)
	end)

	it("maps every name to the same string", function()
		for name, value in HitReaction do
			expect(value).toBe(name)
		end
	end)
end)
