local RKMNControllerFolder = script.Parent.Parent
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

local AirborneBehavior = {}

local DASH_JUMP_FLAG = "IsDashJumping"

local AIRBORNE_STATE_IDS = {
    [MovementStateID.Jump] = true,
    [MovementStateID.Freefall] = true,
}

type StateMachine = StateMachine.StateMachine

local function isPlayerDashJumping(context): boolean
    local wasPlayerDashing = context.PreviousStateId == MovementStateID.Dash
    if wasPlayerDashing then
        return true
    end

    local playerIsWallSliding = context.PreviousStateId == MovementStateID.WallSlide
    local playerIsHoldingDash = context.PlayerInput:IsHoldingDash()
    local isPlayerWallDashJumping = playerIsWallSliding and playerIsHoldingDash
    return isPlayerWallDashJumping
end

function AirborneBehavior.RefreshDashJumpFlag(context): ()
    local wasPlayerInAirborneStatePreviously = AIRBORNE_STATE_IDS[context.PreviousStateId]
    if wasPlayerInAirborneStatePreviously then
        return
    end

    context:ClearFlag(DASH_JUMP_FLAG)
    if isPlayerDashJumping(context) then
        context:SetFlag(DASH_JUMP_FLAG)
    end
end

function AirborneBehavior.AttemptExitToIdleState(stateMachine: StateMachine): boolean
    local context = stateMachine.Context
    local isRising: boolean = context.PhysicsResolver:GetVelocity().Y > 0
    if isRising or not context.CollisionQuery:IsGrounded() then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
end

function AirborneBehavior.AttemptExitToWallSlideState(stateMachine: StateMachine): boolean
    local context = stateMachine.Context
    local moveDirection = context.PlayerInput:GetMoveDirection()
    local isPlayerMoving = moveDirection ~= Direction.None
    if not isPlayerMoving then
        return false
    end

    local isPlayerTouchingWall = context.CollisionQuery:CheckWallContact(moveDirection).Success
    if not isPlayerTouchingWall then
        return false
    end

    stateMachine:ChangeState(MovementStateID.WallSlide)
    return true
end

function AirborneBehavior.DriveHorizontalMovement(context): ()
    local moveDirection = context.PlayerInput:GetMoveDirection()
    local speed: number = if context:HasFlag(DASH_JUMP_FLAG) then MovementConfig.DashSpeed else MovementConfig.MoveSpeed
    context.PhysicsResolver:MoveInDirection(moveDirection, speed)
end

table.freeze(AirborneBehavior)

return AirborneBehavior
