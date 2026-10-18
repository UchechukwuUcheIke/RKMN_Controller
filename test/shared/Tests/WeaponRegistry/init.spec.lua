--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local WeaponRegistry = require(ReplicatedStorage.Combat.Weapon.WeaponRegistry)

local function makeWeapon()
	return { Update = function() end }
end

describe("WeaponRegistry", function()
	it("lists registered weapons in registration order", function()
		local registry = WeaponRegistry.new()
		local first = makeWeapon()
		local second = makeWeapon()
		registry:Register(first)
		registry:Register(second)

		local all = registry:GetAll()

		expect(#all).toBe(2)
		expect(all[1]).toBe(first)
		expect(all[2]).toBe(second)
	end)

	it("reports whether a weapon is registered", function()
		local registry = WeaponRegistry.new()
		local weapon = makeWeapon()

		expect(registry:Has(weapon)).toBe(false)
		registry:Register(weapon)
		expect(registry:Has(weapon)).toBe(true)
		registry:Unregister(weapon)
		expect(registry:Has(weapon)).toBe(false)
	end)

	it("hands out a fresh list each time", function()
		local registry = WeaponRegistry.new()
		registry:Register(makeWeapon())

		local list = registry:GetAll()
		table.clear(list)

		expect(#registry:GetAll()).toBe(1)
	end)

	it("stops listing a weapon once unregistered", function()
		local registry = WeaponRegistry.new()
		local weapon = makeWeapon()
		registry:Register(weapon)
		registry:Unregister(weapon)

		expect(#registry:GetAll()).toBe(0)
	end)

	it("ignores unregistering a weapon that was never registered", function()
		local registry = WeaponRegistry.new()

		expect(function()
			registry:Unregister(makeWeapon())
		end).never.toThrow()
	end)

	it("rejects registering the same weapon twice", function()
		local registry = WeaponRegistry.new()
		local weapon = makeWeapon()
		registry:Register(weapon)

		expect(function()
			registry:Register(weapon)
		end).toThrow()
	end)

	it("drops its weapons and its metatable on Destroy", function()
		local registry = WeaponRegistry.new()
		registry:Register(makeWeapon())

		registry:Destroy()

		expect(#registry._weapons).toBe(0)
		expect(getmetatable(registry)).toBe(nil)
	end)
end)
