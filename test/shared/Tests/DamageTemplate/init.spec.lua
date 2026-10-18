--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)

describe("DamageTemplate.new", function()
	it("keeps the values it is given", function()
		local template = DamageTemplate.new({
			Amount = 3,
			Knockback = Vector2.new(5, 2),
			HitstopDuration = 0.05,
			Tags = { "Buster", "Charged" },
		})

		expect(template.Amount).toBe(3)
		expect(template.Knockback).toEqual(Vector2.new(5, 2))
		expect(template.HitstopDuration).toBe(0.05)
		expect(template.Tags).toEqual({ "Buster", "Charged" })
	end)

	it("defaults knockback, hitstop and tags to nothing", function()
		local template = DamageTemplate.new({ Amount = 1 })

		expect(template.Knockback).toEqual(Vector2.zero)
		expect(template.HitstopDuration).toBe(0)
		expect(template.Tags).toEqual({})
	end)

	it("freezes the template and its tags", function()
		local template = DamageTemplate.new({ Amount = 1, Tags = { "Buster" } })

		expect(table.isfrozen(template)).toBe(true)
		expect(table.isfrozen(template.Tags)).toBe(true)
	end)

	it("does not freeze the tags table the caller passed in", function()
		local tags = { "Buster" }
		DamageTemplate.new({ Amount = 1, Tags = tags })

		expect(table.isfrozen(tags)).toBe(false)
	end)

	it("rejects a negative amount", function()
		expect(function()
			DamageTemplate.new({ Amount = -1 })
		end).toThrow()
	end)

	it("rejects a negative hitstop duration", function()
		expect(function()
			DamageTemplate.new({ Amount = 1, HitstopDuration = -0.1 })
		end).toThrow()
	end)
end)
