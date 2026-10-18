--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local HurtboxContact = require(ReplicatedStorage.Combat.Hitbox.HurtboxContact)

local hurtbox = {}

describe("HurtboxContact.new", function()
	it("keeps the hurtbox and fraction it is given", function()
		local contact = HurtboxContact.new(hurtbox, 0.25)

		expect(contact.Hurtbox).toBe(hurtbox)
		expect(contact.ContactMoveFraction).toBe(0.25)
	end)

	it("accepts both ends of the move", function()
		expect(HurtboxContact.new(hurtbox, 0).ContactMoveFraction).toBe(0)
		expect(HurtboxContact.new(hurtbox, 1).ContactMoveFraction).toBe(1)
	end)

	it("freezes the contact", function()
		expect(table.isfrozen(HurtboxContact.new(hurtbox, 0.5))).toBe(true)
	end)

	it("rejects a fraction outside 0 to 1", function()
		expect(function()
			HurtboxContact.new(hurtbox, -0.01)
		end).toThrow()
		expect(function()
			HurtboxContact.new(hurtbox, 1.01)
		end).toThrow()
	end)
end)
