--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local WeaponFolder = CombatFolder.Weapon
local Weapon = require(WeaponFolder.Weapon)
local WeaponRegistry = require(WeaponFolder.WeaponRegistry)

type Weapon = Weapon.Weapon
type WeaponRegistry = WeaponRegistry.WeaponRegistry

local WeaponFacade = {}
WeaponFacade.__index = WeaponFacade

type WeaponFacadeData = {
	_registry: WeaponRegistry,
}

type WeaponFacadePrototype = typeof(WeaponFacade)

export type WeaponFacade = typeof(setmetatable(
	{} :: WeaponFacadeData,
	{} :: WeaponFacadePrototype
))

function WeaponFacade.new(registry: WeaponRegistry): WeaponFacade
	local data: WeaponFacadeData = {
		_registry = registry,
	}

	return setmetatable(data, WeaponFacade)
end

function WeaponFacade.Register(self: WeaponFacade, weapon: Weapon): ()
	self._registry:Register(weapon)
end

function WeaponFacade.Unregister(self: WeaponFacade, weapon: Weapon): ()
	self._registry:Unregister(weapon)
end

function WeaponFacade.Update(self: WeaponFacade, dt: number): ()
	for _, weapon in self._registry:GetAll() do
		weapon:Update(dt)
	end
end

return WeaponFacade
