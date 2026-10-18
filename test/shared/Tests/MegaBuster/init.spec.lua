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
local MegaBuster = require(ReplicatedStorage.Combat.Weapon.MegaBuster)
local ProjectileSimulation = require(ReplicatedStorage.Combat.Projectile.ProjectileSimulation)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local OWNER_ID = 1

describe("MegaBuster", function()
	local registry
	local simulation
	local resolver
	local muzzle
	local buster

	beforeEach(function()
		registry = HurtboxRegistry.new()
		local hitboxes = HitboxRegistry.new()
		simulation = ProjectileSimulation.new(hitboxes, function()
			return nil
		end)
		resolver = HitResolver.new(hitboxes, registry)
		muzzle = { Position = Vector2.new(0, 0), Direction = Direction.Right }
		buster = MegaBuster.new(simulation, OWNER_ID, Team.Player, function()
			return muzzle
		end)
	end)

	-- One frame of shots: move them, deliver their hits, settle them.
	local function step(dt)
		simulation:Advance(dt)
		simulation:Settle(resolver:Resolve())
	end

	local function makeEnemy(x)
		local received = {}
		local hurtbox = {
			OwnerId = 50,
			Team = Team.Enemy,
			Enabled = true,
			GetBounds = function()
				return Bounds.new(Vector2.new(x, 0), Vector2.new(2, 2))
			end,
			Receive = function(payload)
				table.insert(received, payload)
				return HitResult.Applied
			end,
		}
		registry:Register(hurtbox)
		return received
	end

	it("spawns a lemon at the muzzle flying the way the muzzle faces", function()
		muzzle = { Position = Vector2.new(4, 7), Direction = Direction.Left }

		local projectile = buster:Fire()

		expect(projectile.Definition).toBe(MegaBuster.Lemon)
		expect(projectile.Position).toEqual(Vector2.new(4, 7))
		expect(projectile.Velocity.X).toBe(-MegaBuster.Lemon.Speed)
		expect(projectile.OwnerId).toBe(OWNER_ID)
		expect(projectile.Team).toBe(Team.Player)
	end)

	it("reads the muzzle fresh on every shot", function()
		buster:Fire()
		buster:Update(MegaBuster.Cooldown + 0.01)
		muzzle = { Position = Vector2.new(10, 0), Direction = Direction.Left }

		local second = buster:Fire()

		expect(second.Position.X).toBe(10)
		expect(second.Direction).toBe(Direction.Left)
	end)

	it("is limited by its cooldown", function()
		expect(buster:Fire()).never.toBeNil()
		expect(buster:Fire()).toBeNil()
	end)

	it("fires again once the cooldown has elapsed", function()
		buster:Fire()
		buster:Update(MegaBuster.Cooldown - 0.01)
		expect(buster:Fire()).toBeNil()
		buster:Update(0.02)
		expect(buster:Fire()).never.toBeNil()
	end)

	it("hurts an enemy in its path for the lemon's damage, then ends on the hit", function()
		local received = makeEnemy(10)
		local reasons = {}
		simulation.Despawned:Connect(function(_, reason)
			table.insert(reasons, reason)
		end)

		buster:Fire()
		step(0.3)

		expect(#received).toBe(1)
		expect(received[1].Amount).toBe(MegaBuster.Lemon.Damage.Amount)
		expect(received[1].SourceOwnerId).toBe(OWNER_ID)
		expect(reasons).toEqual({ ProjectileStepOutcome.HitPenetrationExhausted })
	end)

	it("does not hurt its own team", function()
		local received = {}
		registry:Register({
			OwnerId = 60,
			Team = Team.Player,
			Enabled = true,
			GetBounds = function()
				return Bounds.new(Vector2.new(10, 0), Vector2.new(2, 2))
			end,
			Receive = function(payload)
				table.insert(received, payload)
				return HitResult.Applied
			end,
		})

		buster:Fire()
		step(0.3)

		expect(#received).toBe(0)
	end)

	it("expires after its lifetime when nothing is in the way", function()
		local reasons = {}
		simulation.Despawned:Connect(function(_, reason)
			table.insert(reasons, reason)
		end)

		buster:Fire()
		step(MegaBuster.Lemon.Lifetime + 0.1)

		expect(reasons).toEqual({ ProjectileStepOutcome.Expired })
	end)
end)
