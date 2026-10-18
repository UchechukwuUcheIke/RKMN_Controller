local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local StateMachineContext = require(RKMNControllerFolder.FSMContext)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)

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


local function attemptExitToJumpState(stateMachine: StateMachine): boolean
    local inputController = stateMachine.Context.InputController
    if not inputController.HasBufferedJump then
        return false
    end

    inputController:ConsumeJumpBuffer()
    stateMachine:ChangeState(MovementStateID.Jump)
    return true
end

local function attemptExitToDashState(stateMachine: StateMachine): boolean
    local inputController = stateMachine.Context.InputController
    if not inputController.HasBufferedDash then
        return false
    end

    inputController:ConsumeDashBuffer()
    stateMachine:ChangeState(MovementStateID.Dash)
    return true
end

local function drivePlayerMovement(stateMachine: StateMachine): ()
    local context: StateMachineContext = stateMachine.Context
    local moveDirection = context.InputController.MoveDirection
    context.PhysicsResolver:MoveInDirection(moveDirection, MovementConfig.MoveSpeed)
end

function GroundedState.OnStep(self: GroundedState, stateMachine: StateMachine, dt: number): ()
	local success: boolean = attemptExitToFreefallState(stateMachine)
    if success then
        return
    end

    if attemptExitToJumpState(stateMachine) or attemptExitToDashState(stateMachine) then
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