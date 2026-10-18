--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local PostHitReaction = require(ReplicatedStorage.Combat.Hitbox.PostHitReaction)

describe("PostHitReaction", function()
	it("is frozen", function()
		expect(table.isfrozen(PostHitReaction)).toBe(true)
	end)

	it("maps every name to the same string", function()
		for name, value in PostHitReaction do
			expect(value).toBe(name)
		end
	end)
end)
