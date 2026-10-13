local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNController = require(RKMNControllerFolder.RKMNController)
local Signal = typeof(ReplicatedStorage.DevPackages.goodsignal)

local DebuggerFolder = script.Parent
local DebugInputHandler = require(DebuggerFolder.DebugInputHandler)
local DebugUI = require(DebuggerFolder.DebugUI)
local DebugWorldVisualizer = require(DebuggerFolder.DebugWorldVisualizer)
local DiagnosticCollisionQuery = require(DebuggerFolder.DiagnosticCollisionQuery)
local KinematicWorld = require(ReplicatedStorage.KinematicWorld)

type KinematicWorld = KinematicWorld.KinematicWorld
type RKMNController = RKMNController.RKMNController
type DebugInputHandler = DebugInputHandler.InputHandler
type DiagnosticCollisionQuery = DiagnosticCollisionQuery.DiagnosticCollisionQuery
type DebugUI = DebugUI.DebugUI
type DebugWorldVisualizer = DebugWorldVisualizer.DebugWorldVisualizer
type Signal = typeof(Signal)

local DebugFacade = {}
DebugFacade.__index = DebugFacade
DebugFacade.ClassName = "DebugFacade"

type DebugFacadeData = {
	_isActive: boolean,
	_world: WorldRoot,
	_kinematicWorld: KinematicWorld,
	_layerCollector: LayerCollector,
	_renderConnection: RBXScriptConnection?,
	_kinematicController: RKMNController,
	_inputHandler: DebugInputHandler,
	_userInterface: DebugUI,
	_worldVisualizer: DebugWorldVisualizer,
	_connections: {Signal|RBXScriptConnection},
}

type DebugFacadePrototype = typeof({__index = DebugFacade})

export type DebugFacade = typeof(setmetatable(
	{} :: DebugFacadeData,
	{} :: DebugFacadePrototype
))

function DebugFacade.new(world: WorldRoot, layerCollector: LayerCollector, kinematicWorld: KinematicWorld, kinematicController: RKMNController): DebugFacade
	local self = setmetatable({}, DebugFacade)
	
	self._world = world
	self._kinematicWorld = kinematicWorld
	self._kinematicController = kinematicController
	self._layerCollector = layerCollector
	self._isActive = false
	self._connections = {}
	
	self:_instantiateSubModules()
	
	return self
end

function DebugFacade._instantiateSubModules(self: DebugFacade): ()
	self._inputHandler = DebugInputHandler.new()
	self._userInterface = DebugUI.new(self._layerCollector, self._kinematicController)

	-- TODO: Add warning if the collision query grabbed isn't a diagnostic one
	local collisionQuery: DiagnosticCollisionQuery = (self._kinematicController.CollisionQuery :: any) :: DiagnosticCollisionQuery
	self._worldVisualizer = DebugWorldVisualizer.new(self._world, collisionQuery)
end

function DebugFacade._handlePauseToggled(self: DebugFacade): ()
	local isRunning: boolean = self._kinematicWorld:IsRunning()
	if isRunning then
		self._kinematicWorld:Stop()
	else
		self._kinematicWorld:Start()
	end
end

function DebugFacade._handleOnStepForward(self: DebugFacade): ()
	self._kinematicWorld:StepWorld(1/60)
end

function DebugFacade._bindInputSignals(self: DebugFacade): ()
	local onPauseToggledConnection: Signal = self._inputHandler.OnPauseToggled:Connect(function()
		self:_handlePauseToggled()
	end)

	table.insert(self._connections, onPauseToggledConnection)
	
	local onStepForwardConnection: Signal = self._inputHandler.OnStepForward:Connect(function()
		self:_handleOnStepForward()
	end)

	table.insert(self._connections, onStepForwardConnection)
end

function DebugFacade._unbindSignals(self: DebugFacade): ()
	for _, connection: Signal in ipairs(self._connections) do
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

function DebugFacade._enableSubmodules(self: DebugFacade): ()
	self._inputHandler:Enable()
	self._userInterface:Enable()
	self._worldVisualizer:Enable()
end
function DebugFacade._bindRunserviceConnection(self: DebugFacade): ()
	local runServiceConnection: RBXScriptConnection = RunService.RenderStepped:Connect(function(dt)
		self:Update(dt)
	end)
	table.insert(self._connections, runServiceConnection)
end

function DebugFacade.Enable(self: DebugFacade): ()
	if self._isActive then
		return
	end

	self._isActive = true
	--self._kinematicWorld:Disable() uncle bob would be displeased
	self:_bindInputSignals()
	self:_enableSubmodules()
	self:_bindRunserviceConnection()
end

function DebugFacade._disableSubmodules(self: DebugFacade): ()
	self._inputHandler:Disable()
	self._userInterface:Disable()
	self._worldVisualizer:Disable()
end

function DebugFacade.Disable(self: DebugFacade): ()
	if not self._isActive then
		return
	end
	
	self._isActive = false
	
	self:_unbindSignals()
	self:_disableSubmodules()
	--self._kinematicWorld:Enable() -- or turn on the step again, or whatever
end

function DebugFacade.Update(self: DebugFacade, dt: number): ()
	self._userInterface:Render()
	self._worldVisualizer:Render()
end

function DebugFacade.Destroy(self: DebugFacade)
	self:Disable()
	self._inputHandler:Destroy()
	self._userInterface:Destroy()
	self._worldVisualizer:Destroy()
end

return DebugFacade
