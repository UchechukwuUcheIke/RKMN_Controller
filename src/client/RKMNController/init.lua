--!strict

local RKMNController = {}
RKMNController.__index = RKMNController

local MovementConstants = require(script.Parent.MovementConstants)
local TimerUtility = require(script.Parent.TimerUtility)
local InputController = require(script.Parent.InputController)
local CollisionQuery = require(script.Parent.CollisionQuery)
local MovementStateMachine = require(script.Parent.MovementStateMachine)
local ActionStateMachine = require(script.Parent.ActionStateMachine)
local PhysicsResolver = require(script.Parent.PhysicsResolver)
local AnimationController = require(script.Parent.AnimationController)

type TimerUtility = TimerUtility.TimerUtility
type InputController = InputController.InputController
type CollisionQuery = CollisionQuery.CollisionQuery
type MovementStateMachine = MovementStateMachine.MovementStateMachine
type ActionStateMachine = ActionStateMachine.ActionStateMachine
type PhysicsResolver = PhysicsResolver.PhysicsResolver
type AnimationController = AnimationController.AnimationController

type RKMNControllerData = {
    Character: Model,
    IsRunning: boolean,
    InputEnabled: boolean,
    
    Constants: MovementConstants,
    Timers: TimerUtility.TimerUtility,
    Collision: CollisionQuery,
    Input: InputController,
    MovementFSM: MovementStateMachine,
    ActionFSM: ActionStateMachine,
    Physics: PhysicsResolver,
    Animator: AnimationController,
    _connections: {RBXScriptSignal}

}

export type RKMNController = typeof(setmetatable({} :: RKMNControllerData, RKMNController))

return RKMNController