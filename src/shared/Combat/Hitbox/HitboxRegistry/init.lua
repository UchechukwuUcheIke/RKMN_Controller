--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local Hitbox = require(CombatFolder.Hitbox.Hitbox)

type Hitbox = Hitbox.Hitbox

local HitboxRegistry = {}
HitboxRegistry.__index = HitboxRegistry

type HitboxRegistryData = {
	_hitboxes: { Hitbox },
}

type HitboxRegistryPrototype = typeof(HitboxRegistry)

export type HitboxRegistry = typeof(setmetatable(
	{} :: HitboxRegistryData,
	{} :: HitboxRegistryPrototype
))

function HitboxRegistry.new(): HitboxRegistry
	local data: HitboxRegistryData = {
		_hitboxes = {},
	}

	return setmetatable(data, HitboxRegistry)
end

function HitboxRegistry.Register(self: HitboxRegistry, hitbox: Hitbox): ()
	assert(not table.find(self._hitboxes, hitbox), "Hitbox is already registered")
	table.insert(self._hitboxes, hitbox)
end

function HitboxRegistry.Unregister(self: HitboxRegistry, hitbox: Hitbox): ()
	local index = table.find(self._hitboxes, hitbox)
	if index then
		table.remove(self._hitboxes, index)
	end
end

-- The enabled hitboxes in registration order. A fresh list, so callers can register and
-- unregister while they walk it.
function HitboxRegistry.GetEnabled(self: HitboxRegistry): { Hitbox }
	local enabled: { Hitbox } = {}

	for _, hitbox in self._hitboxes do
		if hitbox.Enabled then
			table.insert(enabled, hitbox)
		end
	end

	return enabled
end

function HitboxRegistry.Destroy(self: HitboxRegistry): ()
	table.clear(self._hitboxes)
	setmetatable(self :: any, nil)
end

return HitboxRegistry
