local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

local AirborneState = setmetatable({}, BaseState)
AirborneState.__index = AirborneState

local DASH_JUMP_FLAG = "IsDashJumping"

local AIRBORNE_STATE_IDS = {
    [MovementStateID.Jump] = true,
    [MovementStateID.Freefall] = true,
}

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type AirborneState = BaseState & typeof(AirborneState)

function AirborneState.new(name: string): AirborneState
    local base = BaseState.new(name) :: BaseState
    local self = setmetatable(base, AirborneState)
	return self :: AirborneState
end

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

local function refreshDashJumpFlag(context): ()
    local wasPlayerInAirborneStatePreviously = AIRBORNE_STATE_IDS[context.PreviousStateId]
    if wasPlayerInAirborneStatePreviously then
        return
    end

    context:ClearFlag(DASH_JUMP_FLAG)
    if isPlayerDashJumping(context) then
        context:SetFlag(DASH_JUMP_FLAG)
    end
end

function AirborneState.OnEnter(self: AirborneState, stateMachine: StateMachine)
    local context = stateMachine.Context
    refreshDashJumpFlag(context)

    local isPlayerJumping = self.Id == MovementStateID.Jump
    if not isPlayerJumping then
        return
    end

    context.PhysicsResolver:ApplyJumpImpulse()
end

local function attemptExitToIdleState(stateMachine: StateMachine): boolean
    local context = stateMachine.Context
    local isRising: boolean = context.PhysicsResolver:GetVelocity().Y > 0
    if isRising or not context.CollisionQuery:IsGrounded() then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
end

local function attemptExitToWallSlideState(stateMachine: StateMachine): boolean
    local isPlayerInFreefall = stateMachine.CurrentStateId == MovementStateID.Freefall
    if not isPlayerInFreefall then
        return false
    end

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

local function attemptExitToFreefallState(stateMachine: StateMachine): boolean
    local isPlayerJumping = stateMachine.CurrentStateId == MovementStateID.Jump
    if not isPlayerJumping then
        return false
    end
    
    local isPlayerRisingInAir = stateMachine.Context.PhysicsResolver:GetVelocity().Y > 0
    if isPlayerRisingInAir then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Freefall)
    return true
end

local function attemptExitAirborneState(stateMachine: StateMachine): boolean
    local successfullyExited = (attemptExitToIdleState(stateMachine) 
        or attemptExitToFreefallState(stateMachine)
        or attemptExitToWallSlideState(stateMachine))

    return successfullyExited
end

local function attemptCutJumpEarly(context): ()
    local physicsResolver = context.PhysicsResolver
    local isPlayerRising = physicsResolver:GetVelocity().Y > 0
    local isPlayerHoldingJump = context.PlayerInput:IsHoldingJump()
    if isPlayerHoldingJump or not isPlayerRising then
        return
    end

    physicsResolver:CutRise()
end

local function driveHorizontalMovement(context): ()
    local moveDirection = context.PlayerInput:GetMoveDirection()
    local speed: number = if context:HasFlag(DASH_JUMP_FLAG) then MovementConfig.DashSpeed else MovementConfig.MoveSpeed
    context.PhysicsResolver:MoveInDirection(moveDirection, speed)
end

function AirborneState.OnStep(self: AirborneState, stateMachine: StateMachine, dt: number): ()
	if attemptExitAirborneState(stateMachine) then
        return
    end

    local context = stateMachine.Context
    if self.Id == MovementStateID.Jump then
        attemptCutJumpEarly(context)
    end
    driveHorizontalMovement(context)
end

table.freeze(AirborneState)

return AirborneState
