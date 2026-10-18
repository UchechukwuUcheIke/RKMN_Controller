--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Bounds = require(ReplicatedStorage.Combat.Data.Bounds)
local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)
local Direction = require(ReplicatedStorage.Data.Direction)
local PostHitReaction = require(ReplicatedStorage.Combat.Hitbox.PostHitReaction)
local Hitbox = require(ReplicatedStorage.Combat.Hitbox.Hitbox)
local HitboxRegistry = require(ReplicatedStorage.Combat.Hitbox.HitboxRegistry)
local HitResolver = require(ReplicatedStorage.Combat.Hitbox.HitResolver)
local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local Hurtbox = require(ReplicatedStorage.Combat.Hurtbox.Hurtbox)
local HurtboxRegistry = require(ReplicatedStorage.Combat.Hurtbox.HurtboxRegistry)
local Team = require(ReplicatedStorage.Combat.Data.Team)

-- A 1x1 mover against a 2x2 target centered at (10, 0): the target grows to span x from 8.5 to 11.5.
local MOVER_SIZE = Vector2.new(1, 1)
local TARGET = Bounds.new(Vector2.new(10, 0), Vector2.new(2, 2))

local function sweep(from, to, target)
	return HitResolver.sweepAgainstBox(from, to, MOVER_SIZE, target or TARGET)
end

describe("HitResolver.sweepAgainstBox", function()
	it("returns when the mover first touches the target", function()
		local t = sweep(Vector2.new(0, 0), Vector2.new(20, 0))
		expect(t).toBeCloseTo(0.425, 5)
	end)

	it("hits when the move ends exactly at the target's edge", function()
		local t = sweep(Vector2.new(0, 0), Vector2.new(8.5, 0))
		expect(t).toBeCloseTo(1, 5)
	end)

	it("misses when the move stops short of the target", function()
		expect(sweep(Vector2.new(0, 0), Vector2.new(5, 0))).toBeNil()
	end)

	it("misses a target that is beside the path", function()
		local target = Bounds.new(Vector2.new(10, 5), Vector2.new(2, 2))
		expect(sweep(Vector2.new(0, 0), Vector2.new(20, 0), target)).toBeNil()
	end)

	it("misses a target that is behind the mover", function()
		expect(sweep(Vector2.new(20, 0), Vector2.new(30, 0))).toBeNil()
	end)

	it("hits when moving in the negative direction", function()
		local t = sweep(Vector2.new(20, 0), Vector2.new(0, 0))
		expect(t).toBeCloseTo(0.425, 5)
	end)

	it("hits when moving vertically", function()
		local target = Bounds.new(Vector2.new(0, 10), Vector2.new(2, 2))
		local t = sweep(Vector2.new(0, 0), Vector2.new(0, 20), target)
		expect(t).toBeCloseTo(0.425, 5)
	end)

	it("hits at 0 when the mover starts inside the target", function()
		expect(sweep(Vector2.new(10, 0), Vector2.new(20, 0))).toBe(0)
	end)

	it("handles a mover that did not move", function()
		expect(sweep(Vector2.new(10, 0), Vector2.new(10, 0))).toBe(0)
		expect(sweep(Vector2.new(0, 0), Vector2.new(0, 0))).toBeNil()
	end)

	it("hits a thin target even when the step is huge", function()
		local thin = Bounds.new(Vector2.new(500, 0), Vector2.new(0.1, 2))
		expect(sweep(Vector2.new(0, 0), Vector2.new(10000, 0), thin)).never.toBeNil()
	end)
end)

local function makeHurtbox(ownerId, team, x)
	return Hurtbox.new({
		OwnerId = ownerId,
		Team = team,
		Center = Vector2.new(x, 0),
		Size = Vector2.new(2, 2),
		Receive = function()
			return HitResult.Applied
		end,
	})
end

describe("HitResolver.findHits", function()
	it("returns hits nearest first regardless of registration order", function()
		local registry = HurtboxRegistry.new()
		local far = makeHurtbox(1, Team.Enemy, 40)
		local near = makeHurtbox(2, Team.Enemy, 10)
		registry:Register(far)
		registry:Register(near)

		local hits = HitResolver.findHits(registry, Team.Player, Vector2.new(0, 0), Vector2.new(100, 0), MOVER_SIZE)
		expect(#hits).toBe(2)
		expect(hits[1].Hurtbox).toBe(near)
		expect(hits[2].Hurtbox).toBe(far)
		expect(hits[1].ContactMoveFraction < hits[2].ContactMoveFraction).toBe(true)
	end)

	it("leaves out hurtboxes the path does not touch", function()
		local registry = HurtboxRegistry.new()
		registry:Register(makeHurtbox(1, Team.Enemy, 10))
		registry:Register(makeHurtbox(2, Team.Enemy, 200))

		local hits = HitResolver.findHits(registry, Team.Player, Vector2.new(0, 0), Vector2.new(100, 0), MOVER_SIZE)
		expect(#hits).toBe(1)
	end)

	it("leaves out teams the attacker cannot hurt", function()
		local registry = HurtboxRegistry.new()
		local enemy = makeHurtbox(1, Team.Enemy, 10)
		registry:Register(enemy)
		registry:Register(makeHurtbox(2, Team.Player, 20))

		local hits = HitResolver.findHits(registry, Team.Player, Vector2.new(0, 0), Vector2.new(100, 0), MOVER_SIZE)
		expect(#hits).toBe(1)
		expect(hits[1].Hurtbox).toBe(enemy)
	end)

	it("leaves out hurtboxes the caller excludes", function()
		local registry = HurtboxRegistry.new()
		local skipped = makeHurtbox(1, Team.Enemy, 10)
		local kept = makeHurtbox(2, Team.Enemy, 20)
		registry:Register(skipped)
		registry:Register(kept)

		local hits = HitResolver.findHits(registry, Team.Player, Vector2.new(0, 0), Vector2.new(100, 0), MOVER_SIZE, function(hurtbox)
			return hurtbox == skipped
		end)
		expect(#hits).toBe(1)
		expect(hits[1].Hurtbox).toBe(kept)
	end)

	it("breaks ties by registration order", function()
		local registry = HurtboxRegistry.new()
		local first = makeHurtbox(1, Team.Enemy, 10)
		local second = makeHurtbox(2, Team.Enemy, 10)
		registry:Register(first)
		registry:Register(second)

		local hits = HitResolver.findHits(registry, Team.Player, Vector2.new(0, 0), Vector2.new(100, 0), MOVER_SIZE)
		expect(hits[1].Hurtbox).toBe(first)
		expect(hits[2].Hurtbox).toBe(second)
	end)
end)

-- Targets are 2x2 boxes on the x axis (see makeHurtbox) and hitboxes are 1x1, so a hitbox moving along
-- the axis first touches a target at x - 1.5.
describe("HitResolver:Resolve", function()
	local hitboxes
	local hurtboxes
	local resolver

	local function setup()
		hitboxes = HitboxRegistry.new()
		hurtboxes = HurtboxRegistry.new()
		resolver = HitResolver.new(hitboxes, hurtboxes)
	end

	-- A hurtbox that records every payload it receives and answers with the given result.
	local function addTarget(x, result, team, ownerId)
		local hurtbox = makeHurtbox(ownerId or 2, team or Team.Enemy, x)
		hurtbox.received = {}
		hurtbox.Receive = function(payload)
			table.insert(hurtbox.received, payload)
			return result or HitResult.Applied
		end
		hurtboxes:Register(hurtbox)
		return hurtbox
	end

	-- A hitbox that already moved from the origin to (100, 0).
	local function addHitbox(overrides)
		local config = {
			OwnerId = 1,
			Team = Team.Player,
			Center = Vector2.new(0, 0),
			Size = MOVER_SIZE,
			Damage = DamageTemplate.new({ Amount = 3, Knockback = Vector2.new(5, 2) }),
			Direction = Direction.Right,
		}
		for key, value in overrides or {} do
			config[key] = value
		end
		local hitbox = Hitbox.new(config)
		hitbox:MoveTo(Vector2.new(100, 0))
		hitboxes:Register(hitbox)
		return hitbox
	end

	it("delivers the hitbox's damage to a target its move touched", function()
		setup()
		local target = addTarget(10)
		addHitbox()

		resolver:Resolve()

		expect(#target.received).toBe(1)
		expect(target.received[1].Amount).toBe(3)
		expect(target.received[1].SourceOwnerId).toBe(1)
	end)

	it("pushes knockback the way the hitbox faces", function()
		setup()
		local target = addTarget(10)
		addHitbox({ Direction = Direction.Left })

		resolver:Resolve()

		expect(target.received[1].Knockback.X).toBe(-5)
	end)

	it("leaves out targets the move did not touch", function()
		setup()
		local target = addTarget(200)
		addHitbox()

		resolver:Resolve()

		expect(#target.received).toBe(0)
	end)

	it("leaves out teams the hitbox cannot hurt", function()
		setup()
		local ally = addTarget(10, HitResult.Applied, Team.Player)
		addHitbox()

		resolver:Resolve()

		expect(#ally.received).toBe(0)
	end)

	it("leaves out hurtboxes its own owner has", function()
		setup()
		local own = addTarget(10, HitResult.Applied, Team.Enemy, 1)
		addHitbox({ OwnerId = 1 })

		resolver:Resolve()

		expect(#own.received).toBe(0)
	end)

	it("skips disabled hitboxes", function()
		setup()
		local target = addTarget(10)
		addHitbox({ Enabled = false })

		resolver:Resolve()

		expect(#target.received).toBe(0)
	end)

	it("resolves every hitbox", function()
		setup()
		local target = addTarget(10)
		addHitbox({ OwnerId = 1 })
		addHitbox({ OwnerId = 3 })

		resolver:Resolve()

		expect(#target.received).toBe(2)
	end)

	it("delivers nearest first", function()
		setup()
		local order = {}
		local far = addTarget(40)
		local near = addTarget(10)
		far.Receive = function()
			table.insert(order, "far")
			return HitResult.Applied
		end
		near.Receive = function()
			table.insert(order, "near")
			return HitResult.Applied
		end
		addHitbox()

		resolver:Resolve()

		expect(order).toEqual({ "near", "far" })
	end)

	describe("reach", function()
		it("does not hit targets past the hitbox's reach", function()
			setup()
			local near = addTarget(10)
			local far = addTarget(40)
			-- Near is touched at 8.5 / 100 and far at 38.5 / 100.
			addHitbox():SetReachFraction(0.2)

			resolver:Resolve()

			expect(#near.received).toBe(1)
			expect(#far.received).toBe(0)
		end)

		it("hits a target touched exactly at the reach", function()
			setup()
			local target = addTarget(10)
			addHitbox():SetReachFraction(0.085)

			resolver:Resolve()

			expect(#target.received).toBe(1)
		end)
	end)

	describe("hit memory", function()
		it("does not hit the same target again on a later pass", function()
			setup()
			local target = addTarget(10)
			addHitbox()

			resolver:Resolve()
			resolver:Resolve()

			expect(#target.received).toBe(1)
		end)

		it("tries a target again if it ignored the hit", function()
			setup()
			local target = addTarget(10, HitResult.Ignored)
			addHitbox()

			resolver:Resolve()
			resolver:Resolve()

			expect(#target.received).toBe(2)
		end)
	end)

	describe("OnHit", function()
		it("hears each hit with the target and what it answered", function()
			setup()
			local target = addTarget(10, HitResult.Killed)
			local heard = {}
			addHitbox({
				OnHit = function(hurtbox, result)
					table.insert(heard, { hurtbox, result })
					return PostHitReaction.Continue
				end,
			})

			resolver:Resolve()

			expect(#heard).toBe(1)
			expect(heard[1][1]).toBe(target)
			expect(heard[1][2]).toBe(HitResult.Killed)
		end)

		it("hears hits the target ignored", function()
			setup()
			addTarget(10, HitResult.Ignored)
			local heard = {}
			addHitbox({
				OnHit = function(_, result)
					table.insert(heard, result)
					return PostHitReaction.Continue
				end,
			})

			resolver:Resolve()

			expect(heard).toEqual({ HitResult.Ignored })
		end)

		it("keeps going to later targets while it answers Continue", function()
			setup()
			local near = addTarget(10)
			local far = addTarget(40)
			local hitbox = addHitbox({
				OnHit = function()
					return PostHitReaction.Continue
				end,
			})

			local stops = resolver:Resolve()

			expect(#near.received).toBe(1)
			expect(#far.received).toBe(1)
			expect(stops[hitbox]).toBeNil()
		end)

		it("stops delivering once it answers Stop, and reports where", function()
			setup()
			local near = addTarget(10)
			local far = addTarget(40)
			local hitbox = addHitbox({
				OnHit = function()
					return PostHitReaction.Stop
				end,
			})

			local stops = resolver:Resolve()

			expect(#near.received).toBe(1)
			expect(#far.received).toBe(0)
			expect(stops[hitbox]).toBeCloseTo(0.085, 5)
		end)

		it("only stops the hitbox that said so", function()
			setup()
			local target = addTarget(10)
			local stopper = addHitbox({
				OwnerId = 1,
				OnHit = function()
					return PostHitReaction.Stop
				end,
			})
			local passer = addHitbox({ OwnerId = 3 })

			local stops = resolver:Resolve()

			expect(#target.received).toBe(2)
			expect(stops[stopper]).never.toBeNil()
			expect(stops[passer]).toBeNil()
		end)
	end)
end)
