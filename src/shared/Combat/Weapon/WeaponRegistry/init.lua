--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local WeaponFolder = CombatFolder.Weapon
local Weapon = require(WeaponFolder.Weapon)

type Weapon = Weapon.Weapon

local WeaponRegistry = {}
WeaponRegistry.__index = WeaponRegistry

type WeaponRegistryData = {
	_weapons: { Weapon },
}

type WeaponRegistryPrototype = typeof(WeaponRegistry)

export type WeaponRegistry = typeof(setmetatable(
	{} :: WeaponRegistryData,
	{} :: WeaponRegistryPrototype
))

function WeaponRegistry.new(): WeaponRegistry
	local data: WeaponRegistryData = {
		_weapons = {},
	}

	return setmetatable(data, WeaponRegistry)
end

function WeaponRegistry.Register(self: WeaponRegistry, weapon: Weapon): ()
	assert(not table.find(self._weapons, weapon), "Weapon is already registered")
	table.insert(self._weapons, weapon)
end

function WeaponRegistry.Unregister(self: WeaponRegistry, weapon: Weapon): ()
	local index = table.find(self._weapons, weapon)
	if index then
		table.remove(self._weapons, index)
	end
end

function WeaponRegistry.Has(self: WeaponRegistry, weapon: Weapon): boolean
	return table.find(self._weapons, weapon) ~= nil
end

function WeaponRegistry.GetAll(self: WeaponRegistry): { Weapon }
	return table.clone(self._weapons)
end

function WeaponRegistry.Destroy(self: WeaponRegistry): ()
	table.clear(self._weapons)
	setmetatable(self :: any, nil)
	table.freeze(self)
end

return WeaponRegistry
