--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Health = require(ReplicatedStorage.Combat.Health)

describe("Health.new", function()
	it("starts full", function()
		local health = Health.new(5)

		expect(health.Current).toBe(5)
		expect(health.Max).toBe(5)
		expect(health:IsDepleted()).toBe(false)
	end)

	it("rejects a max that is not positive", function()
		expect(function()
			Health.new(0)
		end).toThrow("positive")
	end)
end)

describe("Health:TakeDamage", function()
	it("lowers the current health and leaves the max alone", function()
		local health = Health.new(5)

		health:TakeDamage(2)

		expect(health.Current).toBe(3)
		expect(health.Max).toBe(5)
	end)

	it("is depleted once the damage adds up to the max", function()
		local health = Health.new(3)

		health:TakeDamage(2)
		health:TakeDamage(1)

		expect(health:IsDepleted()).toBe(true)
	end)

	it("stops at zero", function()
		local health = Health.new(3)

		health:TakeDamage(10)

		expect(health.Current).toBe(0)
	end)

	it("rejects negative damage", function()
		expect(function()
			Health.new(3):TakeDamage(-1)
		end).toThrow("negative")
	end)
end)
