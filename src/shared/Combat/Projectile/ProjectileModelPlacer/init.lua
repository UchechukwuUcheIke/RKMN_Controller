--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = ReplicatedStorage.Data
local Direction = require(DataFolder.Direction)
local ProjectileFolder = CombatFolder.Projectile
local Projectile = require(ProjectileFolder.Projectile)
local ProjectileIDRegistry = require(ProjectileFolder.ProjectileIDRegistry)
local ProjectileSimulation = require(ProjectileFolder.ProjectileSimulation)
local Signal = ReplicatedStorage.DevPackages.goodsignal

type Projectile = Projectile.Projectile
type ProjectileID = ProjectileIDRegistry.ProjectileID
type ProjectileSimulation = ProjectileSimulation.ProjectileSimulation
type Signal = typeof(Signal)

local ProjectileModelPlacer = {}
ProjectileModelPlacer.__index = ProjectileModelPlacer

export type ModelSource = (id: ProjectileID) -> Model

type ProjectileModelPlacerData = {
	_createModel: ModelSource,
	_parentFolder: Folder,
	_models: { [Projectile]: Model },
	_connections: { Signal },
}

type ProjectileModelPlacerPrototype = typeof(ProjectileModelPlacer)

export type ProjectileModelPlacer = typeof(setmetatable(
	{} :: ProjectileModelPlacerData,
	{} :: ProjectileModelPlacerPrototype
))

function ProjectileModelPlacer._populateConnections(self: ProjectileModelPlacer, projectileSimulation: ProjectileSimulation): ()
	table.insert(
		self._connections,
		projectileSimulation.Spawned:Connect(function(projectile: Projectile)
			self:_show(projectile)
		end)
	)
	table.insert(
		self._connections,
		projectileSimulation.Despawned:Connect(function(projectile: Projectile)
			self:_hide(projectile)
		end)
	)
end

function ProjectileModelPlacer._showActiveProjectiles(self: ProjectileModelPlacer, projectileSimulation: ProjectileSimulation): ()
	for _, projectile in projectileSimulation:GetActive() do
		self:_show(projectile)
	end
end

function ProjectileModelPlacer.new(
	projectileSimulation: ProjectileSimulation,
	createModel: ModelSource,
	parentFolder: Folder
): ProjectileModelPlacer
	local self: ProjectileModelPlacer = setmetatable({
		_createModel = createModel,
		_parentFolder = parentFolder,
		_models = {},
		_connections = {},
	} :: ProjectileModelPlacerData, ProjectileModelPlacer)

	
	self:_populateConnections(projectileSimulation)
	self:_showActiveProjectiles(projectileSimulation)

	return self
end

local function place(self: ProjectileModelPlacer, projectile: Projectile, model: Model): ()
	local position = projectile.Position
	local facing = if projectile.Direction == Direction.Left then math.pi else 0
	local newCFrame = CFrame.new(position.X, position.Y, 0) * CFrame.Angles(0, facing, 0)
	model:PivotTo(newCFrame)
end

function ProjectileModelPlacer._show(self: ProjectileModelPlacer, projectile: Projectile): ()
	local model = self._createModel(projectile.Definition.Id)
	self._models[projectile] = model
	place(self, projectile, model)
	model.Parent = self._parentFolder
end

function ProjectileModelPlacer._hide(self: ProjectileModelPlacer, projectile: Projectile): ()
	local model = self._models[projectile]
	if not model then
		return
	end

	place(self, projectile, model)
	self._models[projectile] = nil
	model:Destroy()
end

function ProjectileModelPlacer.Update(self: ProjectileModelPlacer): ()
	for projectile, model in self._models do
		place(self, projectile, model)
	end
end

function ProjectileModelPlacer._destroyConnections(self: ProjectileModelPlacer): ()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

function ProjectileModelPlacer._destroyModels(self: ProjectileModelPlacer): ()
	for _, model in self._models do
		model:Destroy()
	end
	table.clear(self._models)
end

function ProjectileModelPlacer.Destroy(self: ProjectileModelPlacer): ()
	self:_destroyConnections()
	self:_destroyModels()
	
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(ProjectileModelPlacer)

return ProjectileModelPlacer
