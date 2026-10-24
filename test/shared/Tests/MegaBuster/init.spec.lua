--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Direction = require(ReplicatedStorage.Data.Direction)
local ProjectileStepOutcome = require(ReplicatedStorage.Combat.Projectile.ProjectileStepOutcome)
local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local HitboxRegistry = require(ReplicatedStorage.Combat.Hitbox.HitboxRegistry)
local HitResolver = require(ReplicatedStorage.Combat.Hitbox.HitResolver)
local Hurtbox = require(ReplicatedStorage.Combat.Hurtbox.Hurtbox)
local HurtboxRegistry = require(ReplicatedStorage.Combat.Hurtbox.HurtboxRegistry)
local MegaBuster = require(ReplicatedStorage.Combat.Weapon.MegaBuster)
local MegaBusterLemon = require(ReplicatedStorage.Combat.Weapon.MegaBusterLemon)
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
		simulation = ProjectileSimulation.new(hitboxes, {
			FindFractionToWall = function()
				return nil
			end,
		})
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
		local hurtbox = Hurtbox.new({
			OwnerId = 50,
			Team = Team.Enemy,
			Center = Vector2.new(x, 0),
			Size = Vector2.new(2, 2),
			Receive = function(payload)
				table.insert(received, payload)
				return HitResult.Applied
			end,
		})
		registry:Register(hurtbox)
		return received
	end

	it("spawns a lemon at the muzzle flying the way the muzzle faces", function()
		muzzle = { Position = Vector2.new(4, 7), Direction = Direction.Left }

		buster:PressTrigger()

		local shots = simulation:GetActive()
		expect(#shots).toBe(1)
		local projectile = shots[1]
		expect(projectile.Definition).toBe(MegaBusterLemon)
		expect(projectile.Position).toEqual(Vector2.new(4, 7))
		expect(projectile.Velocity.X).toBe(-MegaBusterLemon.Speed)
		expect(projectile.OwnerId).toBe(OWNER_ID)
		expect(projectile.Team).toBe(Team.Player)
	end)

	it("reads the muzzle fresh on every shot", function()
		buster:PressTrigger()
		buster:Update(MegaBuster.Cooldown + 0.01)
		muzzle = { Position = Vector2.new(10, 0), Direction = Direction.Left }

		buster:PressTrigger()

		local second = simulation:GetActive()[2]
		expect(second.Position.X).toBe(10)
		expect(second.Direction).toBe(Direction.Left)
	end)

	it("is limited by its cooldown", function()
		buster:PressTrigger()
		buster:PressTrigger()

		expect(#simulation:GetActive()).toBe(1)
	end)

	it("fires again once the cooldown has elapsed", function()
		buster:PressTrigger()
		buster:Update(MegaBuster.Cooldown - 0.01)
		buster:PressTrigger()
		expect(#simulation:GetActive()).toBe(1)

		buster:Update(0.02)
		buster:PressTrigger()
		expect(#simulation:GetActive()).toBe(2)
	end)

	it("does not repeat the shot while the trigger is held", function()
		buster:PressTrigger()
		buster:Update(1)

		expect(#simulation:GetActive()).toBe(1)
	end)

	it("ignores a release", function()
		expect(function()
			buster:ReleaseTrigger()
		end).never.toThrow()
		expect(#simulation:GetActive()).toBe(0)
	end)

	it("ignores presses while disabled", function()
		buster:SetEnabled(false)

		buster:PressTrigger()

		expect(#simulation:GetActive()).toBe(0)
	end)

	it("does not replay a press made while disabled once enabled again", function()
		buster:SetEnabled(false)
		buster:PressTrigger()
		buster:SetEnabled(true)
		buster:Update(1)

		expect(#simulation:GetActive()).toBe(0)
	end)

	it("fires on a fresh press after being enabled again", function()
		buster:SetEnabled(false)
		buster:SetEnabled(true)

		buster:PressTrigger()

		expect(#simulation:GetActive()).toBe(1)
	end)

	it("hurts an enemy in its path for the lemon's damage, then ends on the hit", function()
		local received = makeEnemy(10)
		local reasons = {}
		simulation.Despawned:Connect(function(_, reason)
			table.insert(reasons, reason)
		end)

		buster:PressTrigger()
		step(0.3)

		expect(#received).toBe(1)
		expect(received[1].Amount).toBe(MegaBusterLemon.Damage.Amount)
		expect(received[1].SourceOwnerId).toBe(OWNER_ID)
		expect(reasons).toEqual({ ProjectileStepOutcome.HitPenetrationExhausted })
	end)

	it("does not hurt its own team", function()
		local received = {}
		registry:Register(Hurtbox.new({
			OwnerId = 60,
			Team = Team.Player,
			Center = Vector2.new(10, 0),
			Size = Vector2.new(2, 2),
			Receive = function(payload)
				table.insert(received, payload)
				return HitResult.Applied
			end,
		}))

		buster:PressTrigger()
		step(0.3)

		expect(#received).toBe(0)
	end)

	it("expires after its lifetime when nothing is in the way", function()
		local reasons = {}
		simulation.Despawned:Connect(function(_, reason)
			table.insert(reasons, reason)
		end)

		buster:PressTrigger()
		step(MegaBusterLemon.Lifetime + 0.1)

		expect(reasons).toEqual({ ProjectileStepOutcome.Expired })
	end)
end)
