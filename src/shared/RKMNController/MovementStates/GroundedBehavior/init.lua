local RKMNControllerFolder = script.Parent.Parent
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local StateMachineContext = require(RKMNControllerFolder.FSMContext)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)

local GroundedBehavior = {}

type StateMachineContext = StateMachineContext.FSMContext
type StateMachine = StateMachine.StateMachine

function GroundedBehavior.AttemptExitToFreefallState(stateMachine: StateMachine): boolean
    local context: StateMachineContext = stateMachine.Context
    local isGrounded: boolean = context.CollisionQuery:IsGrounded()
    if isGrounded then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Freefall)
    return true
end

function GroundedBehavior.AttemptExitToJumpState(stateMachine: StateMachine): boolean
    local playerInput = stateMachine.Context.PlayerInput
    if not playerInput:HasBufferedJump() then
        return false
    end

    playerInput:ConsumeJumpBuffer()
    stateMachine:ChangeState(MovementStateID.Jump)
    return true
end

function GroundedBehavior.AttemptExitToDashState(stateMachine: StateMachine): boolean
    local playerInput = stateMachine.Context.PlayerInput
    if not playerInput:HasBufferedDash() then
        return false
    end

    playerInput:ConsumeDashBuffer()
    stateMachine:ChangeState(MovementStateID.Dash)
    return true
end

function GroundedBehavior.AttemptExitToNonGroundedState(stateMachine: StateMachine): boolean
    local successfullyExited = (GroundedBehavior.AttemptExitToFreefallState(stateMachine)
        or GroundedBehavior.AttemptExitToJumpState(stateMachine)
        or GroundedBehavior.AttemptExitToDashState(stateMachine))

    return successfullyExited
end

function GroundedBehavior.DrivePlayerMovement(context: StateMachineContext): ()
    local moveDirection = context.PlayerInput:GetMoveDirection()
    context.PhysicsResolver:MoveInDirection(moveDirection, MovementConfig.MoveSpeed)
end

function GroundedBehavior.RestorePlayerControls(context: StateMachineContext): ()
    context.PlayerInput:SetEnabled(true)
end

table.freeze(GroundedBehavior)

return GroundedBehavior
