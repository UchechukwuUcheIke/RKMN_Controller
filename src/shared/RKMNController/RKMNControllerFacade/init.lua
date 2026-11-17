--!strict
local RKMNControllerFacade = {}
RKMNControllerFacade.__index = RKMNControllerFacade

local RKMNControllerFolder = script.Parent
local TimerRegistry = require(RKMNControllerFolder.TimerRegistry)
local CollisionQueryFacade = require(RKMNControllerFolder.CollisionQuery.CollisionQueryFacade)
local PlayerInputFacade = require(game:GetService("ReplicatedStorage").PlayerInput.PlayerInputFacade)
local FSMContext = require(RKMNControllerFolder.FSMContext)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolverFacade = require(RKMNControllerFolder.PhysicsResolver.PhysicsResolverFacade)

local MovementState = require(RKMNControllerFolder.MovementStateIDs)


type TimerRegistry = TimerRegistry.TimerRegistry
type CollisionQueryFacade = CollisionQueryFacade.CollisionQueryFacade
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type MovementStateMachine = MovementStateMachine.MovementStateMachine
type PhysicsResolverFacade = PhysicsResolverFacade.PhysicsResolverFacade

-- TODO: Add Action FSM and AnimationController back
type RKMNControllerFacadeData = {
    _inputEnabled: boolean,

    TimerRegistry: TimerRegistry,
    CollisionQuery: CollisionQueryFacade,
    PlayerInput: PlayerInputFacade,
    MovementStateMachine: MovementStateMachine,
    PhysicsResolver: PhysicsResolverFacade,
}

type FSMContext = FSMContext.FSMContext
type FSMContextDependencies = FSMContext.FSMContextDependencies

export type RKMNControllerFacadeDependencies = {
    TimerRegistry: TimerRegistry,
    CollisionQuery: CollisionQueryFacade,
    PlayerInput: PlayerInputFacade,
    MovementStateMachine: MovementStateMachine,
    PhysicsResolver: PhysicsResolverFacade
}

export type RKMNControllerFacade = typeof(setmetatable({} :: RKMNControllerFacadeData, RKMNControllerFacade))

function RKMNControllerFacade.new(dependencies: RKMNControllerFacadeDependencies): RKMNControllerFacade
    local self = {}

    self._inputEnabled = true
    self.TimerRegistry = dependencies.TimerRegistry
    self.CollisionQuery = dependencies.CollisionQuery
    self.PlayerInput = dependencies.PlayerInput
    self.PhysicsResolver = dependencies.PhysicsResolver
    self.MovementStateMachine = dependencies.MovementStateMachine

    setmetatable(self, RKMNControllerFacade)
    return self
end

function RKMNControllerFacade.Reset(self: RKMNControllerFacade): ()
	self.MovementStateMachine:ChangeState(MovementState.Idle)
	self.TimerRegistry:FlushAll()
end

function RKMNControllerFacade.IsInputEnabled(self: RKMNControllerFacade): boolean
    return self._inputEnabled
end


function RKMNControllerFacade.SetInputEnabled(self: RKMNControllerFacade, isEnabled: boolean)
	self._inputEnabled = isEnabled
	self.PlayerInput:SetEnabled(isEnabled)
end

function RKMNControllerFacade.Destroy(self: RKMNControllerFacade)	
	self.PlayerInput:Destroy()
	self.TimerRegistry:Destroy()
	self.PhysicsResolver:Destroy()
	self.MovementStateMachine:Destroy()
	self.CollisionQuery:Destroy()
end


return RKMNControllerFacade