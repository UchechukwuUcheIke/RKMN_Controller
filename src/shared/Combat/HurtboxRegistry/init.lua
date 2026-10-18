--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bounds = require(ReplicatedStorage.Combat.Bounds)
local Hurtbox = require(ReplicatedStorage.Combat.Hurtbox)

type Hurtbox = Hurtbox.Hurtbox

export type HurtboxFilter = (hurtbox: Hurtbox) -> boolean

local HurtboxRegistry = {}
HurtboxRegistry.__index = HurtboxRegistry

type HurtboxRegistryData = {
	_hurtboxes: { Hurtbox },
}

type HurtboxRegistryPrototype = typeof(HurtboxRegistry)

export type HurtboxRegistry = typeof(setmetatable(
	{} :: HurtboxRegistryData,
	{} :: HurtboxRegistryPrototype
))

function HurtboxRegistry.new(): HurtboxRegistry
	local data: HurtboxRegistryData = {
		_hurtboxes = {},
	}

	return setmetatable(data, HurtboxRegistry)
end

function HurtboxRegistry.Register(self: HurtboxRegistry, hurtbox: Hurtbox): ()
	assert(not table.find(self._hurtboxes, hurtbox), "Hurtbox is already registered")
	table.insert(self._hurtboxes, hurtbox)
end

function HurtboxRegistry.Unregister(self: HurtboxRegistry, hurtbox: Hurtbox): ()
	local index = table.find(self._hurtboxes, hurtbox)
	if index then
		table.remove(self._hurtboxes, index)
	end
end

-- Returns the enabled hurtboxes overlapping the bounds that also pass the filter,
-- in registration order. Bounds are read fresh so hurtboxes follow their owners.
function HurtboxRegistry.Query(self: HurtboxRegistry, bounds: Bounds.Bounds, filter: HurtboxFilter?): { Hurtbox }
	local found: { Hurtbox } = {}

	for _, hurtbox in self._hurtboxes do
		if not hurtbox.Enabled then
			continue
		end
		if filter and not filter(hurtbox) then
			continue
		end
		if Bounds.overlaps(bounds, hurtbox.GetBounds()) then
			table.insert(found, hurtbox)
		end
	end

	return found
end

function HurtboxRegistry.Destroy(self: HurtboxRegistry): ()
	table.clear(self._hurtboxes)
	setmetatable(self :: any, nil)
end

return HurtboxRegistry
