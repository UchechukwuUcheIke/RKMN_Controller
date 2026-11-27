--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local ProjectileFolder = CombatFolder.Projectile
local CombatSimulation = require(CombatFolder.CombatSimulation)
local ProjectileIDRegistry = require(ProjectileFolder.ProjectileIDRegistry)
local ProjectileModelPlacer = require(ProjectileFolder.ProjectileModelPlacer)
local RenderPriorities = require(ReplicatedStorage.RenderPriorities)
local RunServiceAdapter = require(ReplicatedStorage.RunServiceAdapter)
local WallQuery = require(ProjectileFolder.WallQuery)

type CombatSimulation = CombatSimulation.CombatSimulation
type ProjectileID = ProjectileIDRegistry.ProjectileID

local CombatSimulationSetup = {}

local function createProjectileModel(id: ProjectileID): Model
	local template = ReplicatedStorage.Assets.Projectile:FindFirstChild(id)
	assert(template and template:IsA("Model"), `No projectile model named {id} in Assets.Projectile`)
	return template:Clone()
end

local function createShotsFolder(world: Instance): Folder
	local shotsFolder = Instance.new("Folder")
	shotsFolder.Name = "Projectiles"
	shotsFolder.Parent = world
	return shotsFolder
end

function CombatSimulationSetup.Setup(): CombatSimulation
	local world = workspace

	local simulation = CombatSimulation.new(WallQuery.new(world))
	local modelPlacer =
		ProjectileModelPlacer.new(simulation.Projectiles, createProjectileModel, createShotsFolder(world))

	local frame = RunServiceAdapter.new("CombatFrame", RenderPriorities.Combat, function(dt: number)
		simulation:Step(dt)
		modelPlacer:Update()
	end)
	frame:Start()

	return simulation
end

return CombatSimulationSetup
