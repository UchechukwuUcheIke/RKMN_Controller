--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)
local Direction = require(ReplicatedStorage.Data.Direction)
local Hitbox = require(ReplicatedStorage.Combat.Hitbox.Hitbox)
local HitboxRegistry = require(ReplicatedStorage.Combat.Hitbox.HitboxRegistry)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local function makeHitbox(enabled)
	return Hitbox.new({
		OwnerId = 1,
		Team = Team.Player,
		Center = Vector2.zero,
		Size = Vector2.new(1, 1),
		Damage = DamageTemplate.new({ Amount = 1 }),
		Direction = Direction.Right,
		Enabled = enabled,
	})
end

describe("HitboxRegistry", function()
	it("returns registered hitboxes in registration order", function()
		local registry = HitboxRegistry.new()
		local first = makeHitbox()
		local second = makeHitbox()
		registry:Register(first)
		registry:Register(second)

		local enabled = registry:GetEnabled()
		expect(#enabled).toBe(2)
		expect(enabled[1]).toBe(first)
		expect(enabled[2]).toBe(second)
	end)

	it("skips disabled hitboxes", function()
		local registry = HitboxRegistry.new()
		registry:Register(makeHitbox(false))

		expect(#registry:GetEnabled()).toBe(0)
	end)

	it("includes a hitbox again once it is re-enabled", function()
		local registry = HitboxRegistry.new()
		local hitbox = makeHitbox(false)
		registry:Register(hitbox)
		hitbox.Enabled = true

		expect(#registry:GetEnabled()).toBe(1)
	end)

	it("stops returning a hitbox once unregistered", function()
		local registry = HitboxRegistry.new()
		local hitbox = makeHitbox()
		registry:Register(hitbox)
		registry:Unregister(hitbox)

		expect(#registry:GetEnabled()).toBe(0)
	end)

	it("ignores unregistering a hitbox that was never registered", function()
		local registry = HitboxRegistry.new()

		expect(function()
			registry:Unregister(makeHitbox())
		end).never.toThrow()
	end)

	it("rejects registering the same hitbox twice", function()
		local registry = HitboxRegistry.new()
		local hitbox = makeHitbox()
		registry:Register(hitbox)

		expect(function()
			registry:Register(hitbox)
		end).toThrow()
	end)

	it("can be walked safely while the caller unregisters hitboxes", function()
		local registry = HitboxRegistry.new()
		registry:Register(makeHitbox())
		registry:Register(makeHitbox())

		for _, hitbox in registry:GetEnabled() do
			registry:Unregister(hitbox)
		end

		expect(#registry:GetEnabled()).toBe(0)
	end)
end)
