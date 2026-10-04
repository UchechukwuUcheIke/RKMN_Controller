local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local KinematicWorld = shared("KinematicWorld")
local RKMNController: RKMNController = require(RKMNControllerFolder.RKMNController)
local Signal = typeof(ReplicatedStorage.DevPackages.Signal)

local DebuggerFolder = script.Parent
local DebugInputHandler = require(DebuggerFolder.DebugInputController)
local DebugUI = require(DebuggerFolder.DebugUI)
local DebugWorldVisualizer = require(DebuggerFolder.DebugWorldVisualizer)

type RKMNController = RKMNController.RKMNController
type KinematicWorld = RKMNController
type DebugInputHandler = DebugInputHandler.DebugInputHandler
type DebugUI = DebugUI.DebugUI
type DebugWorldVisualizer = DebugWorldVisualizer.DebugWorldVisualizer
type RKMNController = RKMNController.RKMNController
type Signal = typeof(Signal)

local DebugFacade = {}
DebugFacade.__index = DebugFacade

type DebugFacadeData = {
	World: KinematicWorld,
	IsActive: boolean,
	_renderConnection: RBXScriptConnection?,
	_kinematicController: RKMNController,
	InputHandler: DebugInputHandler,
	UI: DebugUI,
	WorldVisualizer: DebugWorldVisualizer,
	_connections: {Signal|RBXScriptConnection},
}

type DebugFacadePrototype = typeof(DebugFacade)

export type DebugFacade = typeof(setmetatable(
	{} :: DebugFacadeData,
	{} :: DebugFacadePrototype
))

function DebugFacade.new(kinematicWorld: KinematicWorld, kinematicController: RKMNController): DebugFacade
	local self = setmetatable({}, DebugFacade)
	
	self.World = kinematicWorld
	self._kinematicController = kinematicController
	self.IsActive = false
	self._connections = {}
	
	self:_instantiateSubModules()
	
	return self
end

function DebugFacade._instantiateSubModules(self: DebugFacade): ()
	self.InputHandler = DebugInputHandler.new()
	self.UI = DebugUI.new()
	self.WorldVisualizer = DebugWorldVisualizer.new()
end

function DebugFacade._handlePauseToggled(self: DebugFacade): ()
	local isCurrentlyPaused = self.World:IsPaused()
	self.World:SetPaused(not isCurrentlyPaused)
end

function DebugFacade._handleOnStepForward(self: DebugFacade): ()
	self.World:Step(1/60)
end

function DebugFacade._bindInputSignals(self: DebugFacade): ()
	local onPauseToggledConnection: Signal = self.InputHandler.OnPauseToggled:Connect(function()
		self:_handlePauseToggled()
	end)

	table.insert(self._connections, onPauseToggledConnection)
	
	local onStepForwardConnection: Signal = self.InputHandler.OnStepForward:Connect(function()
		self:_handleOnStepForward()
	end)

	table.insert(self._connections, onStepForwardConnection)
end

function DebugFacade._unbindSignals(self: DebugFacade): ()
	for _, connection: Signal in ipairs(self._connections) do
		connection:Disconnect()
	end
end

function DebugFacade.Toggle(self: DebugFacade): ()
	if self.IsActive then
		self:Disable()
	else
		self:Enable()
	end
end

function DebugFacade._enableSubmodules(self: DebugFacade): ()
	self.InputHandler:Enable()
	self.UI:Enable()
	self.WorldVisualizer:Enable()
end
function DebugFacade._bindRunserviceConnection(self: DebugFacade): ()
	local runServiceConnection: RBXScriptConnection = RunService.RenderStepped:Connect(function(dt)
		self:Update(dt)
	end)
	table.insert(self._connections, runServiceConnection)
end

function DebugFacade.Enable(self: DebugFacade): ()
	if self.IsActive then 
		return 
	end

	self.IsActive = true
	self.World:Disable() -- or turn off, or not do the step anymore

	self:_bindInputSignals()
	self:_enableSubmodules()
	self:_bindRunserviceConnection()
end

function DebugFacade._disableSubmodules(self: DebugFacade): ()
	self.InputHandler:Disable()
	self.UI:Disable()
	self.WorldVisualizer:Disable()
end

function DebugFacade.Disable(self: DebugFacade): ()
	if not self.IsActive then
		return
	end
	
	self.IsActive = false
	
	self:_unbindSignals()
	self:_disableSubmodules()
	self.KinematicWorld:Enable() -- or turn on the step again, or whatever
end

function DebugFacade.Update(self: DebugFacade, dt: number): ()
	self.UI:Render(RKMNController)
	self.WorldVisualizer:Render(RKMNController)
end

function DebugFacade.Destroy(self: DebugFacade)
	self:Disable()
	self.InputHandler:Destroy()
	self.UI:Destroy()
	self.WorldVisualizer:Destroy()
end

return DebugFacade
