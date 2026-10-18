--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Bounds = require(DataFolder.Bounds)
local Hurtbox = require(CombatFolder.Hurtbox.Hurtbox)
local Team = require(DataFolder.Team)

type Hurtbox = Hurtbox.Hurtbox
type Team = Team.Team

local HurtboxRegistry = {}
HurtboxRegistry.__index = HurtboxRegistry

type HurtboxRegistryData = {
	-- Hurtboxes grouped by the team they belong to, in registration order within each team.
	_hurtboxesByTeam: { [Team]: { Hurtbox } },
	-- Teams in the order they first registered a hurtbox, so queries visit teams in a stable order.
	_teamOrder: { Team },
}

type HurtboxRegistryPrototype = typeof(HurtboxRegistry)

export type HurtboxRegistry = typeof(setmetatable(
	{} :: HurtboxRegistryData,
	{} :: HurtboxRegistryPrototype
))

function HurtboxRegistry.new(): HurtboxRegistry
	local data: HurtboxRegistryData = {
		_hurtboxesByTeam = {},
		_teamOrder = {},
	}

	return setmetatable(data, HurtboxRegistry)
end

-- A hurtbox is filed under the team it has when registered, so its Team must not change afterwards.
function HurtboxRegistry.Register(self: HurtboxRegistry, hurtbox: Hurtbox): ()
	local team = hurtbox.Team
	local bucket = self._hurtboxesByTeam[team]
	if not bucket then
		bucket = {}
		self._hurtboxesByTeam[team] = bucket
		table.insert(self._teamOrder, team)
	end

	assert(not table.find(bucket, hurtbox), "Hurtbox is already registered")
	table.insert(bucket, hurtbox)
end

function HurtboxRegistry.Unregister(self: HurtboxRegistry, hurtbox: Hurtbox): ()
	local bucket = self._hurtboxesByTeam[hurtbox.Team]
	if not bucket then
		return
	end

	local index = table.find(bucket, hurtbox)
	if index then
		table.remove(bucket, index)
	end
end

-- Returns the enabled hurtboxes overlapping the bounds that the attacking team can hurt. Teams are
-- visited in the order they first registered, and hurtboxes keep registration order within a team.
-- Bounds are read fresh so hurtboxes follow their owners.
function HurtboxRegistry.Query(self: HurtboxRegistry, bounds: Bounds.Bounds, attackerTeam: Team): { Hurtbox }
	local found: { Hurtbox } = {}

	for _, team in self._teamOrder do
		if not Team.canHurt(attackerTeam, team) then
			continue
		end

		for _, hurtbox in self._hurtboxesByTeam[team] do
			if hurtbox.Enabled and Bounds.overlaps(bounds, hurtbox.GetBounds()) then
				table.insert(found, hurtbox)
			end
		end
	end

	return found
end

function HurtboxRegistry.Destroy(self: HurtboxRegistry): ()
	table.clear(self._hurtboxesByTeam)
	table.clear(self._teamOrder)
	setmetatable(self :: any, nil)
end

return HurtboxRegistry
