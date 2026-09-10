--!strict

local Types = require(script.Parent.Types)

local RKMNController = {}
RKMNController.__index = RKMNController


local MovementConstantsModule = require(script.Parent.MovementConstants)
local TimerUtilityModule = require(script.Parent.TimerUtility)
local CollisionQueryModule = require(script.Parent.CollisionQuery)
local InputControllerModule = require(script.Parent.InputController)
local MovementStateMachineModule = require(script.Parent.MovementStateMachine)
local ActionStateMachineModule = require(script.Parent.ActionStateMachine)
local PhysicsResolverModule = require(script.Parent.PhysicsResolver)
local AnimationControllerModule = require(script.Parent.AnimationController)

export type RKMNController = {
    Character: Model,
    IsRunning: boolean,
    InputEnabled: boolean,
    
    Constants: MovementConstantsModule.MovementConstants,
    TimerUtility: TimerUtilityModule.TimerUtility,
    CollisionQuery: CollisionQueryModule.CollisionQuery,
    InputController: InputControllerModule.InputController,
    MovementFSM: MovementStateMachineModule.MovementStateMachine,
    ActionFSM: ActionStateMachineModule.ActionStateMachine,
    PhysicsResolver: PhysicsResolverModule.PhysicsResolver,
    AnimationController: AnimationControllerModule.AnimationController,
    _connections: {RBXScriptSignal}

}

function RKMNController.new(characterModel: Model): RKMNController
    local self = {}

    self.Character = characterModel
    self.IsRunning = false
    self.InputEnabled = true

    self.Constants = MovementConstantsModule.new(characterModel)
    self.TimerUtility = TimerUtilityModule.new()
    self.CollisionQuery = CollisionQueryModule.new(characterModel, self.Constants)
    self.InputController = InputControllerModule.new(self.TimerUtility)
    self.MovementFSM = MovementStateMachineModule.new(
        self.InputController, 
        self.CollisionQuery)
    self.ActionFSM = ActionStateMachineModule.new(self.InputController)

    self.PhysicsResolver = PhysicsResolverModule.new(
        characterModel,
        self.Constants)
    self.AnimationController = AnimationControllerModule.new(
        characterModel,
        self.MovementFSM,
        self.ActionFSM
    )

    self._connections = {}

    setmetatable(self , RKMNController)
    return self
end

return RKMNController