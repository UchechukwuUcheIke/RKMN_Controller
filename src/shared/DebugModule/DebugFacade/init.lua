--!strict

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNController = require(RKMNControllerFolder.RKMNController)

local DebuggerFolder = script.Parent
local DebugInputHandler = require(DebuggerFolder.DebugInputHandler)
local DebugUI = require(DebuggerFolder.DebugUI)
local DebugWorldVisualizer = require(DebuggerFolder.DebugWorldVisualizer)
local DiagnosticCollisionQuery = require(DebuggerFolder.DiagnosticCollisionQuery)
local KinematicWorld = require(ReplicatedStorage.KinematicWorld)
local RunServiceAdapter = require(ReplicatedStorage.RunServiceAdapter)
local RenderPriorities = require(ReplicatedStorage.RenderPriorities)

type KinematicWorld = KinematicWorld.KinematicWorld
type RKMNController = RKMNController.RKMNController
type DebugInputHandler = DebugInputHandler.InputHandler
type DiagnosticCollisionQuery = DiagnosticCollisionQuery.DiagnosticCollisionQuery
type DebugUI = DebugUI.DebugUI
type DebugWorldVisualizer = DebugWorldVisualizer.DebugWorldVisualizer
type RunServiceAdapter = RunServiceAdapter.RunServiceAdapter
type Connection = { Disconnect: (self: any) -> () }

local RENDER_BIND_NAME = "DebugKinematicLoop"
local SINGLE_STEP_DELTA = 1 / 60

local DebugFacade = {}
DebugFacade.__index = DebugFacade
DebugFacade.ClassName = "DebugFacade"

type DebugFacadeData = {
	_isActive: boolean,
	_isPaused: boolean,
	_world: WorldRoot,
	_kinematicWorld: KinematicWorld,
	_layerCollector: LayerCollector,
	_kinematicController: RKMNController,
	_inputHandler: DebugInputHandler,
	_userInterface: DebugUI,
	_worldVisualizer: DebugWorldVisualizer,
	_runServiceAdapter: RunServiceAdapter,
	_connections: {Connection},
}

type DebugFacadePrototype = typeof({__index = DebugFacade})

export type DebugFacade = typeof(setmetatable(
	{} :: DebugFacadeData,
	{} :: DebugFacadePrototype
))

function DebugFacade.new(world: WorldRoot, layerCollector: LayerCollector, kinematicWorld: KinematicWorld, kinematicController: RKMNController, runServiceAdapter: RunServiceAdapter): DebugFacade
	local self = setmetatable({}, DebugFacade)

	self._world = world
	self._kinematicWorld = kinematicWorld
	self._kinematicController = kinematicController
	self._layerCollector = layerCollector
	self._runServiceAdapter = runServiceAdapter
	self._isActive = false
	self._isPaused = false
	self._connections = {}

	self:_instantiateSubModules()
	self:_bindInputSignals()
	self._inputHandler:Enable()

	return self
end

function DebugFacade._instantiateSubModules(self: DebugFacade): ()
	self._inputHandler = DebugInputHandler.new()
	self._userInterface = DebugUI.new(self._layerCollector, self._kinematicController)

	local collisionQuery: DiagnosticCollisionQuery = (self._kinematicController.CollisionQuery :: any) :: DiagnosticCollisionQuery
	self._worldVisualizer = DebugWorldVisualizer.new(self._world, collisionQuery)
end

function DebugFacade._handlePauseToggled(self: DebugFacade): ()
	if not self._isActive then
		return
	end

	self._isPaused = not self._isPaused
end

function DebugFacade._handleOnStepForward(self: DebugFacade): ()
	if not (self._isActive and self._isPaused) then
		return
	end

	self._kinematicWorld:StepWorld(SINGLE_STEP_DELTA)
end

function DebugFacade._bindInputSignals(self: DebugFacade): ()
	table.insert(self._connections, self._inputHandler.OnDebugToggled:Connect(function()
		self:Toggle()
	end))

	table.insert(self._connections, self._inputHandler.OnPauseToggled:Connect(function()
		self:_handlePauseToggled()
	end))

	table.insert(self._connections, self._inputHandler.OnStepForward:Connect(function()
		self:_handleOnStepForward()
	end))
end

function DebugFacade._unbindSignals(self: DebugFacade): ()
	for _, connection: Connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

function DebugFacade.Toggle(self: DebugFacade): ()
	if self._isActive then
		self:Disable()
	else
		self:Enable()
	end
end

function DebugFacade.IsActive(self: DebugFacade): boolean
	return self._isActive
end

function DebugFacade.IsPaused(self: DebugFacade): boolean
	return self._isPaused
end

function DebugFacade._enableSubmodules(self: DebugFacade): ()
	self._userInterface:Enable()
	self._worldVisualizer:Enable()
end

function DebugFacade._bindRenderStep(self: DebugFacade): ()
	RunService:BindToRenderStep(RENDER_BIND_NAME, RenderPriorities.World, function(deltaTime: number)
		if not self._isPaused then
			self._kinematicWorld:StepWorld(deltaTime)
		end
		self:Update(deltaTime)
	end)
end

function DebugFacade.Enable(self: DebugFacade): ()
	if self._isActive then
		return
	end

	self._isActive = true
	self._isPaused = false
	self._runServiceAdapter:Stop()
	self:_enableSubmodules()
	self:_bindRenderStep()
end

function DebugFacade._disableSubmodules(self: DebugFacade): ()
	self._userInterface:Disable()
	self._worldVisualizer:Disable()
end

function DebugFacade.Disable(self: DebugFacade): ()
	if not self._isActive then
		return
	end

	self._isActive = false
	self._isPaused = false
	RunService:UnbindFromRenderStep(RENDER_BIND_NAME)
	self:_disableSubmodules()
	self._runServiceAdapter:Start()
end

function DebugFacade.Update(self: DebugFacade, dt: number): ()
	self._userInterface:Render()
	self._worldVisualizer:Render()
end

function DebugFacade.Destroy(self: DebugFacade)
	self:Disable()
	self:_unbindSignals()
	self._inputHandler:Destroy()
	self._userInterface:Destroy()
	self._worldVisualizer:Destroy()
end

return DebugFacade
