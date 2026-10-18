--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Bounds = require(ReplicatedStorage.Combat.Data.Bounds)
local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local HurtboxRegistry = require(ReplicatedStorage.Combat.Hurtbox.HurtboxRegistry)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local function makeHurtbox(ownerId, team, x, enabled)
	return {
		OwnerId = ownerId,
		Team = team,
		Enabled = enabled ~= false,
		GetBounds = function()
			return Bounds.new(Vector2.new(x, 0), Vector2.new(4, 4))
		end,
		Receive = function()
			return HitResult.Applied
		end,
	}
end

-- Queries as the player, who can hurt enemies and neutral objects but not other players.
local function queryAround(registry, x, attackerTeam)
	return registry:Query(Bounds.new(Vector2.new(x, 0), Vector2.new(2, 2)), attackerTeam or Team.Player)
end

describe("HurtboxRegistry", function()
	it("returns hurtboxes that overlap the query bounds", function()
		local registry = HurtboxRegistry.new()
		local near = makeHurtbox(1, Team.Enemy, 0)
		local far = makeHurtbox(2, Team.Enemy, 50)
		registry:Register(near)
		registry:Register(far)

		local found = queryAround(registry, 0)
		expect(#found).toBe(1)
		expect(found[1]).toBe(near)
	end)

	it("returns results in registration order", function()
		local registry = HurtboxRegistry.new()
		local first = makeHurtbox(1, Team.Enemy, 0)
		local second = makeHurtbox(2, Team.Enemy, 1)
		registry:Register(first)
		registry:Register(second)

		local found = queryAround(registry, 0)
		expect(found[1]).toBe(first)
		expect(found[2]).toBe(second)
	end)

	it("skips disabled hurtboxes", function()
		local registry = HurtboxRegistry.new()
		registry:Register(makeHurtbox(1, Team.Enemy, 0, false))
		expect(#queryAround(registry, 0)).toBe(0)
	end)

	it("includes a hurtbox again once it is re-enabled", function()
		local registry = HurtboxRegistry.new()
		local hurtbox = makeHurtbox(1, Team.Enemy, 0, false)
		registry:Register(hurtbox)
		hurtbox.Enabled = true
		expect(#queryAround(registry, 0)).toBe(1)
	end)

	it("only returns hurtboxes of teams the attacker can hurt", function()
		local registry = HurtboxRegistry.new()
		local enemy = makeHurtbox(1, Team.Enemy, 0)
		registry:Register(enemy)
		registry:Register(makeHurtbox(2, Team.Player, 0))

		local found = queryAround(registry, 0, Team.Player)
		expect(#found).toBe(1)
		expect(found[1]).toBe(enemy)
	end)

	it("answers differently for different attacking teams", function()
		local registry = HurtboxRegistry.new()
		local player = makeHurtbox(1, Team.Player, 0)
		registry:Register(makeHurtbox(2, Team.Enemy, 0))
		registry:Register(player)

		local found = queryAround(registry, 0, Team.Enemy)
		expect(#found).toBe(1)
		expect(found[1]).toBe(player)
	end)

	it("returns nothing for a team that can hurt no one", function()
		local registry = HurtboxRegistry.new()
		registry:Register(makeHurtbox(1, Team.Enemy, 0))
		registry:Register(makeHurtbox(2, Team.Player, 0))

		expect(#queryAround(registry, 0, Team.Neutral)).toBe(0)
	end)

	it("returns teams in the order they first registered", function()
		local registry = HurtboxRegistry.new()
		local neutral = makeHurtbox(1, Team.Neutral, 0)
		local enemy = makeHurtbox(2, Team.Enemy, 0)
		local laterNeutral = makeHurtbox(3, Team.Neutral, 0)
		registry:Register(neutral)
		registry:Register(enemy)
		registry:Register(laterNeutral)

		local found = queryAround(registry, 0, Team.Player)
		expect(found[1]).toBe(neutral)
		expect(found[2]).toBe(laterNeutral)
		expect(found[3]).toBe(enemy)
	end)

	it("reads bounds fresh so hurtboxes follow their owners", function()
		local registry = HurtboxRegistry.new()
		local x = 100
		registry:Register({
			OwnerId = 1,
			Team = Team.Enemy,
			Enabled = true,
			GetBounds = function()
				return Bounds.new(Vector2.new(x, 0), Vector2.new(4, 4))
			end,
			Receive = function()
				return HitResult.Applied
			end,
		})

		expect(#queryAround(registry, 0)).toBe(0)
		x = 0
		expect(#queryAround(registry, 0)).toBe(1)
	end)

	it("stops returning a hurtbox once unregistered", function()
		local registry = HurtboxRegistry.new()
		local hurtbox = makeHurtbox(1, Team.Enemy, 0)
		registry:Register(hurtbox)
		registry:Unregister(hurtbox)
		expect(#queryAround(registry, 0)).toBe(0)
	end)

	it("ignores unregistering a hurtbox that was never registered", function()
		local registry = HurtboxRegistry.new()
		expect(function()
			registry:Unregister(makeHurtbox(1, Team.Enemy, 0))
		end).never.toThrow()
	end)

	it("rejects registering the same hurtbox twice", function()
		local registry = HurtboxRegistry.new()
		local hurtbox = makeHurtbox(1, Team.Enemy, 0)
		registry:Register(hurtbox)
		expect(function()
			registry:Register(hurtbox)
		end).toThrow()
	end)

	it("can be queried safely while the caller unregisters results", function()
		local registry = HurtboxRegistry.new()
		registry:Register(makeHurtbox(1, Team.Enemy, 0))
		registry:Register(makeHurtbox(2, Team.Enemy, 1))

		for _, hurtbox in queryAround(registry, 0) do
			registry:Unregister(hurtbox)
		end
		expect(#queryAround(registry, 0)).toBe(0)
	end)
end)
