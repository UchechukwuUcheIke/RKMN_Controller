--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Direction = require(ReplicatedStorage.Data.Direction)
local ProjectileStepOutcome = require(ReplicatedStorage.Combat.Projectile.ProjectileStepOutcome)
local Bounds = require(ReplicatedStorage.Combat.Data.Bounds)
local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local HitboxRegistry = require(ReplicatedStorage.Combat.Hitbox.HitboxRegistry)
local HitResolver = require(ReplicatedStorage.Combat.Hitbox.HitResolver)
local HurtboxRegistry = require(ReplicatedStorage.Combat.Hurtbox.HurtboxRegistry)
local ProjectileSimulation = require(ReplicatedStorage.Combat.Projectile.ProjectileSimulation)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local OWNER_ID = 1
local ORIGIN = Vector2.new(0, 0)

local function makeDefinition(overrides)
	local definition = {
		Id = "Buster",
		Speed = 100,
		Lifetime = 1,
		Size = Vector2.new(1, 1),
		Damage = {
			Amount = 3,
			Knockback = Vector2.new(5, 2),
			HitstopDuration = 0.05,
			Tags = { "Buster" },
		},
		TargetPenetrationLimit = 0,
	}
	for key, value in overrides or {} do
		definition[key] = value
	end
	return definition
end

local nextOwnerId = 100

-- A 2x2 target at (x, 0) that records every payload it receives.
local function makeTarget(x, team, result)
	nextOwnerId += 1
	local received = {}
	local hurtbox = {
		OwnerId = nextOwnerId,
		Team = team or Team.Enemy,
		Enabled = true,
		GetBounds = function()
			return Bounds.new(Vector2.new(x, 0), Vector2.new(2, 2))
		end,
		Receive = function(payload)
			table.insert(received, payload)
			return result or HitResult.Applied
		end,
	}
	return hurtbox, received
end

describe("ProjectileSimulation", function()
	local registry
	local hitboxes
	local wallT
	local simulation
	local resolver

	beforeEach(function()
		registry = HurtboxRegistry.new()
		hitboxes = HitboxRegistry.new()
		wallT = nil
		simulation = ProjectileSimulation.new(hitboxes, function()
			return wallT
		end)
		resolver = HitResolver.new(hitboxes, registry)
	end)

	-- One frame: move the shots, deliver their hits, settle them.
	local function step(dt)
		simulation:Advance(dt)
		simulation:Settle(resolver:Resolve())
	end

	local function spawn(definition, direction, ownerId)
		return simulation:Spawn(definition or makeDefinition(), ownerId or OWNER_ID, Team.Player, ORIGIN, direction or Direction.Right)
	end

	local function recordDespawns()
		local reasons = {}
		simulation.Despawned:Connect(function(_, reason)
			table.insert(reasons, reason)
		end)
		return reasons
	end

	describe("spawning", function()
		it("returns the projectile, tracks it, and fires Spawned", function()
			local spawned = {}
			simulation.Spawned:Connect(function(projectile)
				table.insert(spawned, projectile)
			end)

			local projectile = spawn()
			expect(projectile).never.toBeNil()
			expect(#simulation:GetActive()).toBe(1)
			expect(spawned[1]).toBe(projectile)
		end)
	end)

	describe("hitboxes", function()
		it("registers a hitbox for each projectile, owned by the shooter", function()
			local projectile = spawn()

			local registered = hitboxes:GetEnabled()
			expect(#registered).toBe(1)
			expect(registered[1]).toBe(projectile.Hitbox)
			expect(projectile.Hitbox.OwnerId).toBe(OWNER_ID)
			expect(projectile.Hitbox.Team).toBe(Team.Player)
		end)

		it("takes the hitbox back out when the projectile despawns", function()
			spawn(makeDefinition({ Lifetime = 0.5 }))

			step(1)

			expect(#hitboxes:GetEnabled()).toBe(0)
		end)

		it("takes the hitboxes of live projectiles out when destroyed", function()
			spawn()

			simulation:Destroy()

			expect(#hitboxes:GetEnabled()).toBe(0)
		end)

		it("leaves a projectile spawned mid-frame alone until the next frame", function()
			local first = spawn()
			simulation:Advance(0.1)
			local late = spawn()

			resolver:Resolve()
			simulation:Settle({})

			expect(first.Position.X).toBeCloseTo(10, 5)
			expect(late.Position.X).toBe(0)
			expect(#simulation:GetActive()).toBe(2)
		end)
	end)

	describe("movement", function()
		it("moves right by speed times dt", function()
			local projectile = spawn(makeDefinition(), Direction.Right)
			step(0.1)
			expect(projectile.Position.X).toBeCloseTo(10, 5)
		end)

		it("moves left when fired left", function()
			local projectile = spawn(makeDefinition(), Direction.Left)
			step(0.1)
			expect(projectile.Position.X).toBeCloseTo(-10, 5)
		end)

		it("despawns as Expired once its lifetime runs out", function()
			local reasons = recordDespawns()
			local projectile = spawn(makeDefinition({ Lifetime = 1 }))
			step(0.6)
			expect(#reasons).toBe(0)
			step(0.6)
			expect(reasons).toEqual({ ProjectileStepOutcome.Expired })
			expect(#simulation:GetActive()).toBe(0)
			-- It only travels for the lifetime it had left, not the whole second step.
			expect(projectile.Position.X).toBeCloseTo(100, 5)
		end)
	end)

	describe("hits", function()
		it("delivers a payload to the first enemy in the path and despawns as Hit", function()
			local reasons = recordDespawns()
			local target, received = makeTarget(50)
			registry:Register(target)

			local projectile = spawn()
			step(1)

			expect(#received).toBe(1)
			expect(reasons).toEqual({ ProjectileStepOutcome.HitPenetrationExhausted })
			-- Stops where the shot first touches the target: 50 - 1 (target) - 0.5 (shot)
			expect(projectile.Position.X).toBeCloseTo(48.5, 5)
		end)

		it("fills the payload from the definition and the owner", function()
			local target, received = makeTarget(50)
			registry:Register(target)

			spawn()
			step(1)

			local payload = received[1]
			expect(payload.Amount).toBe(3)
			expect(payload.SourceOwnerId).toBe(OWNER_ID)
			expect(payload.Team).toBe(Team.Player)
			expect(payload.HitstopDuration).toBe(0.05)
			expect(payload.Tags).toEqual({ "Buster" })
			expect(payload.Knockback).toBe(Vector2.new(5, 2))
		end)

		it("mirrors knockback for a shot flying left", function()
			local target, received = makeTarget(-50)
			registry:Register(target)

			spawn(makeDefinition(), Direction.Left)
			step(1)

			expect(received[1].Knockback).toBe(Vector2.new(-5, 2))
		end)

		it("fires Hit with the projectile, hurtbox and result", function()
			local target = makeTarget(50, Team.Enemy, HitResult.Killed)
			registry:Register(target)

			local events = {}
			simulation.Hit:Connect(function(projectile, hurtbox, result)
				table.insert(events, { projectile, hurtbox, result })
			end)

			local projectile = spawn()
			step(1)

			expect(events[1][1]).toBe(projectile)
			expect(events[1][2]).toBe(target)
			expect(events[1][3]).toBe(HitResult.Killed)
		end)

		it("hits a thin target even with a huge step", function()
			local target, received = makeTarget(500)
			target.GetBounds = function()
				return Bounds.new(Vector2.new(500, 0), Vector2.new(0.1, 2))
			end
			registry:Register(target)

			spawn(makeDefinition({ Speed = 10000, Lifetime = 5 }))
			step(1)

			expect(#received).toBe(1)
		end)

		it("misses a target outside the path", function()
			local target, received = makeTarget(50)
			target.GetBounds = function()
				return Bounds.new(Vector2.new(50, 20), Vector2.new(2, 2))
			end
			registry:Register(target)

			spawn()
			step(1)

			expect(#received).toBe(0)
		end)

		it("does not hit a target the shot has not reached yet", function()
			local target, received = makeTarget(50)
			registry:Register(target)

			spawn()
			step(0.1)

			expect(#received).toBe(0)
			expect(#simulation:GetActive()).toBe(1)
		end)

		it("does not hit hurtboxes of a team it cannot hurt", function()
			local ally, received = makeTarget(50, Team.Player)
			registry:Register(ally)

			spawn()
			step(1)

			expect(#received).toBe(0)
		end)

		it("does not hit its own owner", function()
			local own, received = makeTarget(50, Team.Enemy)
			own.OwnerId = OWNER_ID
			registry:Register(own)

			spawn()
			step(1)

			expect(#received).toBe(0)
		end)

		it("hits only the nearest target when it cannot penetrate", function()
			local far, farReceived = makeTarget(80)
			local near, nearReceived = makeTarget(30)
			registry:Register(far)
			registry:Register(near)

			spawn()
			step(1)

			expect(#nearReceived).toBe(1)
			expect(#farReceived).toBe(0)
		end)
	end)

	describe("penetration", function()
		it("goes through targets until it exceeds its TargetPenetrationLimit", function()
			local reasons = recordDespawns()
			local first, firstReceived = makeTarget(20)
			local second, secondReceived = makeTarget(40)
			local third, thirdReceived = makeTarget(60)
			registry:Register(first)
			registry:Register(second)
			registry:Register(third)

			spawn(makeDefinition({ TargetPenetrationLimit = 1 }))
			step(1)

			expect(#firstReceived).toBe(1)
			expect(#secondReceived).toBe(1)
			expect(#thirdReceived).toBe(0)
			expect(reasons).toEqual({ ProjectileStepOutcome.HitPenetrationExhausted })
		end)

		it("keeps flying after a hit while it still has penetration left", function()
			local target, received = makeTarget(20)
			registry:Register(target)

			spawn(makeDefinition({ TargetPenetrationLimit = 1 }))
			step(0.5)

			expect(#received).toBe(1)
			expect(#simulation:GetActive()).toBe(1)
		end)

		it("never hits the same target twice", function()
			local target, received = makeTarget(0)
			target.GetBounds = function()
				return Bounds.new(Vector2.new(20, 0), Vector2.new(60, 2))
			end
			registry:Register(target)

			spawn(makeDefinition({ TargetPenetrationLimit = 5 }))
			step(0.1)
			step(0.1)
			step(0.1)

			expect(#received).toBe(1)
		end)
	end)

	describe("hit results", function()
		it("flies through a target that ignores the hit and hits the one behind it", function()
			local ignoring, ignoredReceived = makeTarget(20, Team.Enemy, HitResult.Ignored)
			local solid, solidReceived = makeTarget(40)
			registry:Register(ignoring)
			registry:Register(solid)

			spawn()
			step(1)

			expect(#ignoredReceived).toBe(1)
			expect(#solidReceived).toBe(1)
		end)

		it("tries an ignoring target again on a later step", function()
			local ignoring, received = makeTarget(0, Team.Enemy, HitResult.Ignored)
			ignoring.GetBounds = function()
				return Bounds.new(Vector2.new(20, 0), Vector2.new(60, 2))
			end
			registry:Register(ignoring)

			spawn()
			step(0.1)
			step(0.1)

			expect(#received).toBe(2)
		end)

		it("is consumed by a target that blocks, even with penetration left", function()
			local reasons = recordDespawns()
			local blocker = makeTarget(20, Team.Enemy, HitResult.Blocked)
			local behind, behindReceived = makeTarget(40)
			registry:Register(blocker)
			registry:Register(behind)

			spawn(makeDefinition({ TargetPenetrationLimit = 5 }))
			step(1)

			expect(reasons).toEqual({ ProjectileStepOutcome.Blocked })
			expect(#behindReceived).toBe(0)
		end)

		it("goes through a target that was killed like any other hit", function()
			local killed = makeTarget(20, Team.Enemy, HitResult.Killed)
			local behind, behindReceived = makeTarget(40)
			registry:Register(killed)
			registry:Register(behind)

			spawn(makeDefinition({ TargetPenetrationLimit = 1 }))
			step(1)

			expect(#behindReceived).toBe(1)
		end)
	end)

	describe("walls", function()
		it("despawns as Wall at the point of obstruction", function()
			local reasons = recordDespawns()
			wallT = 0.2

			local projectile = spawn()
			step(1)

			expect(reasons).toEqual({ ProjectileStepOutcome.HitWall })
			expect(projectile.Position.X).toBeCloseTo(20, 5)
		end)

		it("protects a target that is behind the wall", function()
			local target, received = makeTarget(50)
			registry:Register(target)
			wallT = 0.2

			spawn()
			step(1)

			expect(#received).toBe(0)
		end)

		it("still hits a target that is in front of the wall", function()
			local reasons = recordDespawns()
			local target, received = makeTarget(30)
			registry:Register(target)
			wallT = 0.9

			spawn()
			step(1)

			expect(#received).toBe(1)
			expect(reasons).toEqual({ ProjectileStepOutcome.HitPenetrationExhausted })
		end)
	end)

	describe("Destroy", function()
		it("tears the simulation down so it can't be used afterwards", function()
			spawn()
			simulation:Destroy()
			expect(function()
				simulation:GetActive()
			end).toThrow()
		end)
	end)
end)
