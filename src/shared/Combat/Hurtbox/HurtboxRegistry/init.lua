--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Bounds = require(DataFolder.Bounds)
local HurtboxFolder = CombatFolder.Hurtbox
local Hurtbox = require(HurtboxFolder.Hurtbox)
local Team = require(DataFolder.Team)

type Hurtbox = Hurtbox.Hurtbox
type Team = Team.Team

local HurtboxRegistry = {}
HurtboxRegistry.__index = HurtboxRegistry

type HurtboxRegistryData = {
	_hurtboxesByTeam: { [Team]: { Hurtbox } },
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

function HurtboxRegistry._getHurtboxTeamBucket(self: HurtboxRegistry, team: Team): { Hurtbox }
	local bucket = self._hurtboxesByTeam[team]
	if not bucket then
		bucket = {}
		self._hurtboxesByTeam[team] = bucket
		table.insert(self._teamOrder, team)
	end

	return bucket
end

function HurtboxRegistry.Register(self: HurtboxRegistry, hurtbox: Hurtbox): ()
	local team: Team = hurtbox.Team
	local bucket = self:_getHurtboxTeamBucket(team)

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

function HurtboxRegistry.Query(self: HurtboxRegistry, bounds: Bounds.Bounds, attackerTeam: Team): { Hurtbox }
	local found: { Hurtbox } = {}

	for _, team: Team in self._teamOrder do
		if not Team.canHurt(attackerTeam, team) then
			continue
		end

		for _, hurtbox in self._hurtboxesByTeam[team] do
			local isElegibleHurtbox = hurtbox.Enabled and Bounds.overlaps(bounds, hurtbox:GetBounds())
			if isElegibleHurtbox then
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
	table.freeze(self)
end

return HurtboxRegistry
