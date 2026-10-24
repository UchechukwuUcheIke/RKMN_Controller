--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Direction = require(ReplicatedStorage.Data.Direction)
local HitboxRegistry = require(ReplicatedStorage.Combat.Hitbox.HitboxRegistry)
local ProjectileModelPlacer = require(ReplicatedStorage.Combat.Projectile.ProjectileModelPlacer)
local ProjectileSimulation = require(ReplicatedStorage.Combat.Projectile.ProjectileSimulation)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local OWNER_ID = 1

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

local simulation
local folder
local requestedIds
local placer

local function createModel(id)
	table.insert(requestedIds, id)
	return Instance.new("Model")
end

local function spawnShot(position, direction, overrides)
	return simulation:Spawn(
		makeDefinition(overrides),
		OWNER_ID,
		Team.Player,
		position or Vector2.new(0, 0),
		direction or Direction.Right
	)
end

-- Runs one frame of the simulation with no hits and no walls.
local function step(dt)
	simulation:Advance(dt)
	simulation:Settle({})
end

local function modelOf(index)
	return folder:GetChildren()[index]
end

beforeEach(function()
	simulation = ProjectileSimulation.new(HitboxRegistry.new(), {
		FindFractionToWall = function()
			return nil
		end,
	})
	folder = Instance.new("Folder")
	requestedIds = {}
	placer = ProjectileModelPlacer.new(simulation, createModel, folder)
end)

describe("ProjectileModelPlacer", function()
	it("shows a model for a spawned shot, made from the shot's kind", function()
		spawnShot(Vector2.new(10, 5), Direction.Right, { Id = "Buster" })

		expect(requestedIds).toEqual({ "Buster" })
		expect(#folder:GetChildren()).toBe(1)
		expect(modelOf(1):GetPivot().Position).toEqual(Vector3.new(10, 5, 0))
	end)

	it("shows models for shots that were already flying", function()
		local other = ProjectileSimulation.new(HitboxRegistry.new(), {
			FindFractionToWall = function()
				return nil
			end,
		})
		other:Spawn(makeDefinition(), OWNER_ID, Team.Player, Vector2.new(4, 4), Direction.Right)
		local parent = Instance.new("Folder")

		ProjectileModelPlacer.new(other, createModel, parent)

		expect(#parent:GetChildren()).toBe(1)
	end)

	it("faces a shot flying left the other way", function()
		spawnShot(Vector2.new(0, 0), Direction.Right)
		spawnShot(Vector2.new(0, 0), Direction.Left)

		expect(modelOf(1):GetPivot().RightVector.X > 0).toBe(true)
		expect(modelOf(2):GetPivot().RightVector.X < 0).toBe(true)
	end)
end)

describe("ProjectileModelPlacer:Update", function()
	it("moves each model to where its shot is now", function()
		spawnShot(Vector2.new(0, 0), Direction.Right, { Speed = 100 })
		step(0.1)

		expect(modelOf(1):GetPivot().Position.X).toBeCloseTo(0, 3)

		placer:Update()

		expect(modelOf(1):GetPivot().Position.X).toBeCloseTo(10, 3)
	end)
end)

describe("when a shot despawns", function()
	it("removes its model", function()
		spawnShot(Vector2.new(0, 0), Direction.Right, { Lifetime = 0.5 })

		step(1)

		expect(#folder:GetChildren()).toBe(0)
	end)

	it("keeps the models of the shots still flying", function()
		spawnShot(Vector2.new(0, 0), Direction.Right, { Lifetime = 0.5 })
		spawnShot(Vector2.new(0, 0), Direction.Right, { Lifetime = 5 })

		step(1)

		expect(#folder:GetChildren()).toBe(1)
	end)
end)

describe("ProjectileModelPlacer:Destroy", function()
	it("removes every model and stops following the simulation", function()
		spawnShot()
		spawnShot()

		placer:Destroy()
		spawnShot()

		expect(#folder:GetChildren()).toBe(0)
	end)
end)
