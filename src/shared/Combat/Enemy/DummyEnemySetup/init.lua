--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local CombatSimulation = require(CombatFolder.CombatSimulation)
local DummyEnemy = require(CombatFolder.Enemy.DummyEnemy)

type CombatSimulation = CombatSimulation.CombatSimulation
type DummyEnemy = DummyEnemy.DummyEnemy

local TAG = "DummyEnemy"
local MAX_HEALTH = 3
-- Owner ids count down from here so they never match a player's, which are positive in a live game
-- and small negatives in a Studio test server.
local FIRST_OWNER_ID = -1000

local DummyEnemySetup = {}

-- Movement collides with anything it can cast against, so the player must be able to pass through.
local function makePassable(model: Model): ()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
		end
	end
end

-- Brings every tagged model in the workspace to life, including ones that appear later.
function DummyEnemySetup.Setup(simulation: CombatSimulation): ()
	local enemies: { [Instance]: DummyEnemy } = {}
	local nextOwnerId = FIRST_OWNER_ID

	local function add(instance: Instance)
		local isNewDummy = not enemies[instance] and instance:IsA("Model") and instance:IsDescendantOf(workspace)
		if not isNewDummy then
			return
		end

		local model = instance :: Model
		makePassable(model)
		enemies[model] = DummyEnemy.new(model, nextOwnerId, MAX_HEALTH, simulation.HurtboxRegistry)
		nextOwnerId -= 1
	end

	local function remove(instance: Instance)
		local enemy = enemies[instance]
		if not enemy then
			return
		end

		enemies[instance] = nil
		enemy:Destroy()
	end

	CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(remove)

	for _, instance in CollectionService:GetTagged(TAG) do
		-- Spawned so that one badly built model does not stop the rest.
		task.spawn(add, instance)
	end
end

return DummyEnemySetup
