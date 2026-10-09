--!strict

local Types = require(script.Parent.Types)
local RunService = game:GetService("RunService")

local RKMNController = {}
RKMNController.__index = RKMNController

local RKMNControllerFolder = script.Parent
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local MovementStats = require(RKMNControllerFolder.MovementStats)
local TimerUtility = require(RKMNControllerFolder.TimerUtility)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local InputController = require(RKMNControllerFolder.InputController)
local FSMContext = require(RKMNControllerFolder.FSMContext)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)

local MovementState = require(RKMNControllerFolder.MovementStateIDRegistry)

-- TODO: Add Action FSM and AnimationController back
type RKMNControllerData = {
    Character: Model,
    InputEnabled: boolean,
    
    Constants: CollisionConstants.CollisionConstants,
    TimerUtility: TimerUtility.TimerUtility,
    CollisionQuery: CollisionQuery.CollisionQuery,
    InputController: InputController.InputController,
    MovementStateMachine: MovementStateMachine.MovementStateMachine,
    PhysicsResolver: PhysicsResolver.PhysicsResolver,
}

type FSMContext = FSMContext.FSMContext
type FSMContextDependencies = FSMContext.FSMContextDependencies

export type RKMNController = typeof(setmetatable({} :: RKMNControllerData, RKMNController))

function RKMNController.new(world: WorldRoot, characterModel: Model): RKMNController
    local self = {}

    self.Character = characterModel
    self.InputEnabled = true

    self.Constants = CollisionConstants.new(characterModel)
    self.MovementStats = MovementStats.new()
    self.TimerUtility = TimerUtility.new()
    self.CollisionQuery = CollisionQuery.new(world, characterModel, self.Constants)
    self.InputController = InputController.new(self.TimerUtility)
    self.PhysicsResolver = PhysicsResolver.new(characterModel, self.MovementStats, self.CollisionQuery)

    local FSMContextDependencies: FSMContextDependencies = {
        InputController  = self.InputController,
        CollisionQuery = self.CollisionQuery,
        PhysicsResolver = self.PhysicsResolver,
        TimerUtility = self.TimerUtility
    }
    local FSMContext: FSMContext = FSMContext.new(FSMContextDependencies)
    self.MovementStateMachine = MovementStateMachine.new(FSMContext)

    setmetatable(self, RKMNController)
    return self
end

function RKMNController.Reset(self: RKMNController): ()
	self.MovementStateMachine:ChangeState(MovementState.Idle)
	self.TimerUtility:FlushAll()
end


function RKMNController.SetInputEnabled(self: RKMNController, isEnabled: boolean)
	self.InputEnabled = isEnabled
	self.InputController:SetEnabled(isEnabled)
	
	if not isEnabled then
		self.InputController:FlushActiveInputs()
	end
end

function RKMNController.Destroy(self: RKMNController)	
	self.InputController:Destroy()
	self.TimerUtility:Destroy()
	self.PhysicsResolver:Destroy()
	self.MovementStateMachine:Destroy()
	self.CollisionQuery:Destroy()
end


return RKMNController