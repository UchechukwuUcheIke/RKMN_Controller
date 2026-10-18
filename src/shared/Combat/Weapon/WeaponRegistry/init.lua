--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local Weapon = require(CombatFolder.Weapon.Weapon)

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

-- Updates every registered weapon, in registration order.
function WeaponRegistry.Update(self: WeaponRegistry, dt: number): ()
	-- Snapshot, so weapons that register or unregister during the pass don't disturb it.
	for _, weapon in table.clone(self._weapons) do
		-- A weapon unregistered earlier in this pass is no longer updated.
		if table.find(self._weapons, weapon) then
			weapon:Update(dt)
		end
	end
end

function WeaponRegistry.Destroy(self: WeaponRegistry): ()
	table.clear(self._weapons)
	setmetatable(self :: any, nil)
end

return WeaponRegistry
