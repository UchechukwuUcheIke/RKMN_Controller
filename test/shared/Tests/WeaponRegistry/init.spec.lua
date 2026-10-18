--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local WeaponRegistry = require(ReplicatedStorage.Combat.Weapon.WeaponRegistry)

local function makeWeapon(onUpdate)
	local weapon = { updates = {} }
	function weapon.Update(_, dt)
		table.insert(weapon.updates, dt)
		if onUpdate then
			onUpdate()
		end
	end
	return weapon
end

describe("WeaponRegistry", function()
	it("updates every registered weapon each frame", function()
		local registry = WeaponRegistry.new()
		local first = makeWeapon()
		local second = makeWeapon()
		registry:Register(first)
		registry:Register(second)

		registry:Update(0.1)
		registry:Update(0.2)

		expect(first.updates).toEqual({ 0.1, 0.2 })
		expect(second.updates).toEqual({ 0.1, 0.2 })
	end)

	it("updates in registration order", function()
		local registry = WeaponRegistry.new()
		local order = {}
		registry:Register(makeWeapon(function()
			table.insert(order, "first")
		end))
		registry:Register(makeWeapon(function()
			table.insert(order, "second")
		end))

		registry:Update(0.1)

		expect(order).toEqual({ "first", "second" })
	end)

	it("stops updating a weapon once unregistered", function()
		local registry = WeaponRegistry.new()
		local weapon = makeWeapon()
		registry:Register(weapon)
		registry:Unregister(weapon)

		registry:Update(0.1)

		expect(#weapon.updates).toBe(0)
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

	it("does not update a weapon that an earlier weapon unregistered this frame", function()
		local registry = WeaponRegistry.new()
		local second = makeWeapon()
		registry:Register(makeWeapon(function()
			registry:Unregister(second)
		end))
		registry:Register(second)

		registry:Update(0.1)

		expect(#second.updates).toBe(0)
	end)

	it("does not disturb the pass when a weapon unregisters itself", function()
		local registry = WeaponRegistry.new()
		local leaver
		leaver = makeWeapon(function()
			registry:Unregister(leaver)
		end)
		local survivor = makeWeapon()
		registry:Register(leaver)
		registry:Register(survivor)

		registry:Update(0.1)

		expect(survivor.updates).toEqual({ 0.1 })
	end)
end)
