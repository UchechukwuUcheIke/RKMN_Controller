--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Bounds = require(DataFolder.Bounds)
local DamagePayload = require(DataFolder.DamagePayload)
local PostHitReaction = require(CombatFolder.Hitbox.PostHitReaction)
local HitResult = require(CombatFolder.Hurtbox.HitResult)
local Hitbox = require(CombatFolder.Hitbox.Hitbox)
local HitboxRegistry = require(CombatFolder.Hitbox.HitboxRegistry)
local Hurtbox = require(CombatFolder.Hurtbox.Hurtbox)
local HurtboxContact = require(CombatFolder.Hitbox.HurtboxContact)
local HurtboxRegistry = require(CombatFolder.Hurtbox.HurtboxRegistry)
local Team = require(DataFolder.Team)

type Hitbox = Hitbox.Hitbox
type Hurtbox = Hurtbox.Hurtbox
type Team = Team.Team
type HurtboxContact = HurtboxContact.HurtboxContact

-- Lets the caller rule out hurtboxes the attacker's team could otherwise hit, such as its own owner
-- or a target it already struck.
export type HurtboxExclusion = (hurtbox: Hurtbox) -> boolean

local HitResolver = {}
HitResolver.__index = HitResolver

type HitResolverData = {
	_hitboxes: HitboxRegistry.HitboxRegistry,
	_hurtboxes: HurtboxRegistry.HurtboxRegistry,
}

type HitResolverPrototype = typeof(HitResolver)

export type HitResolver = typeof(setmetatable(
	{} :: HitResolverData,
	{} :: HitResolverPrototype
))

export type StopFractions = { [Hitbox]: number }

local function clipAxis(
	origin: number,
	delta: number,
	slabMin: number,
	slabMax: number,
	tMin: number,
	tMax: number
): (number?, number?)
	if delta == 0 then
		if origin < slabMin or origin > slabMax then
			return nil, nil
		end
		return tMin, tMax
	end

	local entry = (slabMin - origin) / delta
	local exit = (slabMax - origin) / delta
	if entry > exit then
		entry, exit = exit, entry
	end

	local newMin = math.max(tMin, entry)
	local newMax = math.min(tMax, exit)
	if newMin > newMax then
		return nil, nil
	end

	return newMin, newMax
end

-- A box of the given size moves from `from` to `to`. Returns when (0 to 1) it first touches the
-- target, or nil if it never does. Growing the target by half the mover's size reduces the moving
-- box to a moving point, which the slab method handles. Starting inside the target returns 0.
function HitResolver.sweepAgainstBox(from: Vector2, to: Vector2, size: Vector2, target: Bounds.Bounds): number?
	local delta = to - from
	local reach = (target.Size + size) / 2
	local min = target.Center - reach
	local max = target.Center + reach

	local tMin, tMax = clipAxis(from.X, delta.X, min.X, max.X, 0, 1)
	if not tMin or not tMax then
		return nil
	end

	tMin, tMax = clipAxis(from.Y, delta.Y, min.Y, max.Y, tMin, tMax)
	if not tMin then
		return nil
	end

	return tMin
end

-- A contact plus its position in the registry's results, which breaks ties between equal fractions.
type OrderedContact = {
	Contact: HurtboxContact,
	Order: number,
}

-- Every hurtbox the attacking team can hurt that the move touches, nearest first.
function HitResolver.findHits(
	registry: HurtboxRegistry.HurtboxRegistry,
	attackerTeam: Team,
	from: Vector2,
	to: Vector2,
	size: Vector2,
	isExcluded: HurtboxExclusion?
): { HurtboxContact }
	local sweptBounds = Bounds.fromSweep(from, to, size)
	local candidates = registry:Query(sweptBounds, attackerTeam)

	local ordered: { OrderedContact } = {}
	for order, hurtbox in candidates do
		if isExcluded and isExcluded(hurtbox) then
			continue
		end

		local t = HitResolver.sweepAgainstBox(from, to, size, hurtbox:GetBounds())
		if t then
			table.insert(ordered, { Contact = HurtboxContact.new(hurtbox, t), Order = order })
		end
	end

	table.sort(ordered, function(a: OrderedContact, b: OrderedContact)
		if a.Contact.ContactMoveFraction ~= b.Contact.ContactMoveFraction then
			return a.Contact.ContactMoveFraction < b.Contact.ContactMoveFraction
		end
		return a.Order < b.Order
	end)

	local contacts: { HurtboxContact } = {}
	for _, entry in ordered do
		table.insert(contacts, entry.Contact)
	end

	return contacts
end

function HitResolver.new(hitboxes: HitboxRegistry.HitboxRegistry, hurtboxes: HurtboxRegistry.HurtboxRegistry): HitResolver
	local data: HitResolverData = {
		_hitboxes = hitboxes,
		_hurtboxes = hurtboxes,
	}

	return setmetatable(data, HitResolver)
end

-- Delivers one hitbox's hits, nearest first, until it runs out of reach or its owner says stop.
-- Returns the fraction it stopped at, or nil if it was not stopped.
function HitResolver._resolveHitbox(self: HitResolver, hitbox: Hitbox): number?
	local contacts = HitResolver.findHits(
		self._hurtboxes,
		hitbox.Team,
		hitbox:GetPreviousCenter(),
		hitbox:GetCenter(),
		hitbox.Size,
		function(hurtbox: Hurtbox): boolean
			return hurtbox.OwnerId == hitbox.OwnerId or hitbox:HasHit(hurtbox)
		end
	)

	for _, contact in contacts do
		if contact.ContactMoveFraction > hitbox.ReachFraction then
			break
		end

		local hurtbox = contact.Hurtbox
		local result = hurtbox.Receive(
			DamagePayload.fromTemplate(hitbox.Damage, hitbox.OwnerId, hitbox.Team, hitbox.Direction)
		)

		-- A target that ignored the hit wasn't really struck, so the hitbox may try it again.
		if result ~= HitResult.Ignored then
			hitbox:RecordHit(hurtbox)
		end

		local onHit = hitbox.OnHit
		if onHit and onHit(hurtbox, result) == PostHitReaction.Stop then
			return contact.ContactMoveFraction
		end
	end

	return nil
end

-- One pass over every enabled hitbox, delivering the hits each one made during its latest move.
function HitResolver.Resolve(self: HitResolver): StopFractions
	local stops: StopFractions = {}

	for _, hitbox in self._hitboxes:GetEnabled() do
		local stopFraction = self:_resolveHitbox(hitbox)
		if stopFraction then
			stops[hitbox] = stopFraction
		end
	end

	return stops
end

function HitResolver.Destroy(self: HitResolver): ()
	setmetatable(self :: any, nil)
end

return HitResolver
