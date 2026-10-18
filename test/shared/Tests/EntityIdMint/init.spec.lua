--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local EntityIdMint = require(ReplicatedStorage.Combat.EntityIdMint)

describe("EntityIdMint", function()
	it("mints a different id every time", function()
		local mint = EntityIdMint.new()

		local first = mint:Mint()
		local second = mint:Mint()
		local third = mint:Mint()

		expect(first).never.toBe(second)
		expect(second).never.toBe(third)
		expect(first).never.toBe(third)
	end)

	it("keeps ids separate between mints", function()
		local one = EntityIdMint.new()
		local other = EntityIdMint.new()

		expect(one:Mint()).toBe(other:Mint())
	end)
end)
