--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNController = require(RKMNControllerFolder.RKMNController)

local DebugModuleFolder = script.Parent
local Widgets = DebugModuleFolder.Widgets
local PhysicsWidget = require(Widgets.PhysicsWidget)
local InputWidget = require(Widgets.InputWidget)
local MovementStateMachineWidget = require(Widgets.MovementStateMachineWidget)
local FlagsWidget = require(Widgets.FlagsWidget)

local DebugUI = {}
DebugUI.__index = DebugUI

type PhysicsWidget = PhysicsWidget.PhysicsWidget
type InputWidget = InputWidget.InputWidget
type FlagsWidget = FlagsWidget.FlagsWidget
type MovementStateMachineWidget = MovementStateMachineWidget.MovementStateMachineWidget
type RKMNController = RKMNController.RKMNController

type DebugUIData = {
	_kinematicController: RKMNController,
	_canvas: LayerCollector,
	physicsWidget: PhysicsWidget,
	inputWidget: InputWidget,
	movementStateMachineWidget: MovementStateMachineWidget,
	flagsWidget: FlagsWidget,
}

type DebugUIPrototype = typeof(DebugUI)

export type DebugUI = typeof(setmetatable(
	{} :: DebugUIData,
	{} :: DebugUIPrototype
))

function DebugUI.new(layerCollector: LayerCollector, kinematicController: RKMNController): DebugUI
	assert(kinematicController)

	local data = {
        _kinematicController = kinematicController,
        _canvas = layerCollector,
    } :: DebugUIData

	local self = setmetatable(data, DebugUI)
	
	self:_createAndMountGUI()
	return self
end

function DebugUI.Enable(self: DebugUI): ()
	if self._canvas then
		self._canvas.Enabled = true
	end
end

function DebugUI.Disable(self: DebugUI): ()
	if self._canvas then
		self._canvas.Enabled = false
	end
end

function DebugUI.Render(self: DebugUI): ()
	self.physicsWidget:Render()
	self.flagsWidget:Render({})
	self.inputWidget:Render()
	self.movementStateMachineWidget:Render()
end

function DebugUI:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

function DebugUI._createScreenGUI(self: DebugUI): ()
    self._canvas = Instance.new("ScreenGui")
	self._canvas.Name = "KinematicDebugHUD"
	self._canvas.ResetOnSpawn = false
	self._canvas.Enabled = false
end

function DebugUI._mountScreenGUIToPlayer(self: DebugUI): ()
    local localPlayer: Player = game.Players.LocalPlayer
    local playerGUI: PlayerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
	self._canvas.Parent = playerGUI
end

function DebugUI._createAndMountPhysicsWidget(self: DebugUI): ()
	local physicsWidget: PhysicsWidget = PhysicsWidget.new(self._kinematicController.PhysicsResolver)
	self.physicsWidget = physicsWidget
	self.physicsWidget:MountTo(self._canvas)
end

function DebugUI._createAndMountFlagWidget(self: DebugUI): ()
	local flagsWidget: FlagsWidget = FlagsWidget.new()
	self.flagsWidget = flagsWidget
	self.flagsWidget:MountTo(self._canvas)
end

function DebugUI._createAndMountMovementStateMachineWidget(self: DebugUI): ()
	local movementStateMachineWidget: MovementStateMachineWidget = MovementStateMachineWidget.new(self._kinematicController.MovementStateMachine)
	self.movementStateMachineWidget = movementStateMachineWidget
	self.movementStateMachineWidget:MountTo(self._canvas)
end

function DebugUI._createAndMountInputWidget(self: DebugUI): ()
	local inputWidget: InputWidget = InputWidget.new(self._kinematicController.InputController)
	self.inputWidget = inputWidget
	self.inputWidget:MountTo(self._canvas)
end

function DebugUI._createAndMountSubwidgets(self: DebugUI): ()
	self:_createAndMountFlagWidget()
	self:_createAndMountPhysicsWidget()
	self:_createAndMountMovementStateMachineWidget()
	self:_createAndMountInputWidget()
end

function DebugUI._createAndMountGUI(self: DebugUI): ()
	self:_createScreenGUI()
	self:_mountScreenGUIToPlayer()
	self:_createAndMountSubwidgets()
end

table.freeze(DebugUI)

return DebugUI
