--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local WeaponFacade = require(ReplicatedStorage.Combat.Weapon.WeaponFacade)
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

local function makeFacade()
	local registry = WeaponRegistry.new()
	return WeaponFacade.new(registry), registry
end

describe("WeaponFacade", function()
	it("updates every registered weapon each frame", function()
		local facade = makeFacade()
		local first = makeWeapon()
		local second = makeWeapon()
		facade:Register(first)
		facade:Register(second)

		facade:Update(0.1)
		facade:Update(0.2)

		expect(first.updates).toEqual({ 0.1, 0.2 })
		expect(second.updates).toEqual({ 0.1, 0.2 })
	end)

	it("updates in registration order", function()
		local facade = makeFacade()
		local order = {}
		facade:Register(makeWeapon(function()
			table.insert(order, "first")
		end))
		facade:Register(makeWeapon(function()
			table.insert(order, "second")
		end))

		facade:Update(0.1)

		expect(order).toEqual({ "first", "second" })
	end)

	it("stops updating a weapon once unregistered", function()
		local facade = makeFacade()
		local weapon = makeWeapon()
		facade:Register(weapon)
		facade:Unregister(weapon)

		facade:Update(0.1)

		expect(#weapon.updates).toBe(0)
	end)

	it("does not disturb the pass when a weapon unregisters itself", function()
		local facade = makeFacade()
		local leaver
		leaver = makeWeapon(function()
			facade:Unregister(leaver)
		end)
		local survivor = makeWeapon()
		facade:Register(leaver)
		facade:Register(survivor)

		facade:Update(0.1)

		expect(survivor.updates).toEqual({ 0.1 })
	end)

	it("registers into the registry it was given", function()
		local facade, registry = makeFacade()
		local weapon = makeWeapon()

		facade:Register(weapon)

		expect(registry:Has(weapon)).toBe(true)
	end)

	it("works with any registry that offers the same calls", function()
		local weapon = makeWeapon()
		local fakeRegistry = {
			GetAll = function()
				return { weapon }
			end,
		}
		local facade = WeaponFacade.new(fakeRegistry)

		facade:Update(0.5)

		expect(weapon.updates).toEqual({ 0.5 })
	end)
end)
