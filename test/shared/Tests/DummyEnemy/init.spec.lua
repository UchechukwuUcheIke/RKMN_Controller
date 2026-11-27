--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Bounds = require(ReplicatedStorage.Combat.Data.Bounds)
local DamagePayload = require(ReplicatedStorage.Combat.Data.DamagePayload)
local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)
local Direction = require(ReplicatedStorage.Data.Direction)
local DummyEnemy = require(ReplicatedStorage.Combat.Enemy.DummyEnemy)
local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local HurtboxRegistry = require(ReplicatedStorage.Combat.Hurtbox.HurtboxRegistry)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local OWNER_ID = -1000
local MAX_HEALTH = 3
local POSITION = Vector3.new(10, 5, 0)

local registry
local folder
local model
local enemy

local function makeModel()
	local newModel = Instance.new("Model")
	local root = Instance.new("Part")
	root.Size = Vector3.new(2, 4, 1)
	root.Position = POSITION
	root.Parent = newModel
	newModel.PrimaryPart = root
	return newModel
end

local function hurtboxesInReach()
	return registry:Query(Bounds.new(Vector2.new(10, 5), Vector2.new(1, 1)), Team.Player)
end

local function damage(amount)
	local template = DamageTemplate.new({ Amount = amount })
	return DamagePayload.fromTemplate(template, 1, Team.Player, Direction.Right)
end

beforeEach(function()
	registry = HurtboxRegistry.new()
	folder = Instance.new("Folder")
	model = makeModel()
	model.Parent = folder
	enemy = DummyEnemy.new(model, OWNER_ID, MAX_HEALTH, registry)
end)

describe("DummyEnemy.new", function()
	it("registers a hurtbox the size of the model that players can hit", function()
		local hurtboxes = hurtboxesInReach()

		expect(#hurtboxes).toBe(1)
		expect(hurtboxes[1].OwnerId).toBe(OWNER_ID)
		expect(hurtboxes[1].Team).toBe(Team.Enemy)
		expect(hurtboxes[1]:GetBounds().Size).toEqual(Vector2.new(2, 4))
		expect(hurtboxes[1]:GetBounds().Center).toEqual(Vector2.new(10, 5))
	end)

	it("starts at full health", function()
		expect(enemy.Health.Current).toBe(MAX_HEALTH)
	end)
end)

describe("when a DummyEnemy is hit", function()
	it("takes the damage and stays while it has health left", function()
		local hurtbox = hurtboxesInReach()[1]

		local result = hurtbox.Receive(damage(1))

		expect(result).toBe(HitResult.Applied)
		expect(enemy.Health.Current).toBe(2)
		expect(model.Parent).toBe(folder)
		expect(#hurtboxesInReach()).toBe(1)
	end)

	it("is destroyed by the hit that empties its health", function()
		local hurtbox = hurtboxesInReach()[1]

		hurtbox.Receive(damage(2))
		local result = hurtbox.Receive(damage(1))

		expect(result).toBe(HitResult.Killed)
		expect(model.Parent).toBeNil()
		expect(#hurtboxesInReach()).toBe(0)
	end)

	it("ignores hits once it is dead", function()
		local hurtbox = hurtboxesInReach()[1]
		hurtbox.Receive(damage(MAX_HEALTH))

		expect(hurtbox.Receive(damage(1))).toBe(HitResult.Ignored)
	end)
end)

describe("DummyEnemy:Destroy", function()
	it("removes the hurtbox and the model", function()
		enemy:Destroy()

		expect(#hurtboxesInReach()).toBe(0)
		expect(model.Parent).toBeNil()
	end)

	it("is safe to call after the enemy has already died", function()
		hurtboxesInReach()[1].Receive(damage(MAX_HEALTH))

		expect(function()
			enemy:Destroy()
		end).never.toThrow()
	end)
end)
