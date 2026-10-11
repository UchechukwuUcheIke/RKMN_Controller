local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local StateMachineContext = require(RKMNControllerFolder.FSMContext)
local Direction = require(RKMNControllerFolder.Direction)

local GroundedState = setmetatable({}, BaseState)
GroundedState.__index = GroundedState

type StateMachineContext = StateMachineContext.FSMContext
type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
type Direction = Direction.Direction
export type GroundedState = BaseState

function GroundedState.new(name: string): GroundedState
    local base = BaseState.new(name) :: BaseState
    local self = setmetatable(base, GroundedState)
	return self :: GroundedState
end

local function attemptExitToFreefallState(stateMachine: StateMachine): boolean
    local isGrounded: boolean = stateMachine.Context.CollisionQuery:IsGrounded()
    if isGrounded then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Freefall)
    return true
end

local function attemptExitToIdleOrWalkState(stateMachine: StateMachine): ()
    local context: StateMachineContext = stateMachine.Context
    local moveDirection = context.InputController.MoveDirection
    local isMoving: boolean = moveDirection ~= Direction.None
    local newStateID: string = if isMoving then MovementStateID.Walk else MovementStateID.Idle 
    stateMachine:ChangeState(newStateID)
end


local function drivePlayerMovement(stateMachine: StateMachine): ()
    --TODO: Get player speed
    -- Get player direction
    -- Move player in that  direction
    local context: StateMachineContext = stateMachine.Context
    local moveDirection = context.InputController.MoveDirection

    local xVelocity: number = 0
    if moveDirection == Direction.Left then
        xVelocity = -10
    elseif moveDirection == Direction.Right then
        xVelocity = 10
    end
    
    -- There's a cleaner way to do this, my head just hurts
    stateMachine.Context.PhysicsResolver:SetTargetXVelocity(xVelocity, moveDirection)
end

function GroundedState.OnStep(self: GroundedState, stateMachine: StateMachine, dt: number): ()
	local success: boolean = attemptExitToFreefallState(stateMachine)
    if success then
        return
    end
    drivePlayerMovement(stateMachine)
    attemptExitToIdleOrWalkState(stateMachine)
end

local function restorePlayerControls(stateMachine: StateMachine): ()
    stateMachine.Context.InputController:SetEnabled(true)
end

function GroundedState.OnExit(self: GroundedState, stateMachine: StateMachine): ()
    restorePlayerControls(stateMachine)
end

table.freeze(GroundedState)

return GroundedState