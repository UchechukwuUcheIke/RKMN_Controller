--!strict
local RKMNController = {}
RKMNController.__index = RKMNController

local RKMNControllerFolder = script.Parent
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local TimerUtility = require(RKMNControllerFolder.TimerUtility)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local PlayerInputFacade = require(game:GetService("ReplicatedStorage").PlayerInput.PlayerInputFacade)
local FSMContext = require(RKMNControllerFolder.FSMContext)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)

local MovementState = require(RKMNControllerFolder.MovementStateIDRegistry)


type CollisionConstants = CollisionConstants.CollisionConstants
type TimerUtility = TimerUtility.TimerUtility
type CollisionQuery = CollisionQuery.CollisionQuery
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type MovementStateMachine = MovementStateMachine.MovementStateMachine
type PhysicsResolver = PhysicsResolver.PhysicsResolver

-- TODO: Add Action FSM and AnimationController back
type RKMNControllerData = {
    _inputEnabled: boolean,
    
    Constants: CollisionConstants,
    TimerUtility: TimerUtility,
    CollisionQuery: CollisionQuery,
    PlayerInput: PlayerInputFacade,
    MovementStateMachine: MovementStateMachine,
    PhysicsResolver: PhysicsResolver,
}

type FSMContext = FSMContext.FSMContext
type FSMContextDependencies = FSMContext.FSMContextDependencies

export type RKMNControllerDependencies = {
    Constants: CollisionConstants,
    TimerUtility: TimerUtility,
    CollisionQuery: CollisionQuery,
    PlayerInput: PlayerInputFacade,
    MovementStateMachine: MovementStateMachine,
    PhysicsResolver: PhysicsResolver
}

export type RKMNController = typeof(setmetatable({} :: RKMNControllerData, RKMNController))

function RKMNController.new(dependencies: RKMNControllerDependencies): RKMNController
    local self = {}

    self._inputEnabled = true
    self.Constants = dependencies.Constants
    self.TimerUtility = dependencies.TimerUtility
    self.CollisionQuery = dependencies.CollisionQuery
    self.PlayerInput = dependencies.PlayerInput
    self.PhysicsResolver = dependencies.PhysicsResolver
    self.MovementStateMachine = dependencies.MovementStateMachine

    setmetatable(self, RKMNController)
    return self
end

function RKMNController.Reset(self: RKMNController): ()
	self.MovementStateMachine:ChangeState(MovementState.Idle)
	self.TimerUtility:FlushAll()
end

function RKMNController.IsInputEnabled(self: RKMNController): boolean
    return self._inputEnabled
end


function RKMNController.SetInputEnabled(self: RKMNController, isEnabled: boolean)
	self._inputEnabled = isEnabled
	self.PlayerInput:SetEnabled(isEnabled)
end

function RKMNController.Destroy(self: RKMNController)	
	self.PlayerInput:Destroy()
	self.TimerUtility:Destroy()
	self.PhysicsResolver:Destroy()
	self.MovementStateMachine:Destroy()
	self.CollisionQuery:Destroy()
end


return RKMNController