local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)
local TimerID = require(RKMNControllerFolder.TimerIDRegistry)
local Direction = require(RKMNControllerFolder.Direction)

local AirborneState = setmetatable({}, BaseState)
AirborneState.__index = AirborneState

local CUT_JUMP_FLAG = "HasCutJump"
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

function AirborneState._resolveAirborneVariables(self: AirborneState, stateMachine: StateMachine): ()
    local context = stateMachine.Context
    if AIRBORNE_STATE_IDS[context.PreviousStateId] then
        return
    end

    context:ClearFlag(CUT_JUMP_FLAG)
    context:ClearFlag(DASH_JUMP_FLAG)
    if context.PreviousStateId == MovementStateID.Dash then
        context:SetFlag(DASH_JUMP_FLAG)
    end
end

function AirborneState.OnEnter(self: AirborneState, stateMachine: StateMachine)
    self:_resolveAirborneVariables(stateMachine)

    if self.Id == MovementStateID.Jump then
        local context = stateMachine.Context
        context.PhysicsResolver:ApplyJumpImpulse()
        context.TimerUtility:StartTimer(TimerID.JumpRise, MovementConfig.TimeToApex)
    end
end

local function attemptEndRise(stateMachine: StateMachine): ()
    local context = stateMachine.Context
    if context.TimerUtility:IsComplete(TimerID.JumpRise) then
        context.PhysicsResolver:EndRise()
    end
end

local function attemptExitToIdleState(stateMachine: StateMachine): boolean
    local context = stateMachine.Context
    local isRising: boolean = context.PhysicsResolver.Velocity.Y > 0
    if isRising or not context.CollisionQuery:IsGrounded() then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
end

local function attemptExitToWallSlideState(stateMachine: StateMachine): boolean
    if stateMachine.CurrentStateId ~= MovementStateID.Freefall then
        return false
    end

    local context = stateMachine.Context
    local moveDirection = context.InputController.MoveDirection
    if moveDirection == Direction.None then
        return false
    end

    if not context.CollisionQuery:CheckWallContact(moveDirection).Success then
        return false
    end

    stateMachine:ChangeState(MovementStateID.WallSlide)
    return true
end

local function attemptExitToFreefallState(stateMachine: StateMachine): boolean
    if stateMachine.CurrentStateId ~= MovementStateID.Jump then
        return false
    end

    if stateMachine.Context.PhysicsResolver.Velocity.Y > 0 then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Freefall)
    return true
end

local EXIT_CHECKS = {
    attemptExitToIdleState,
    attemptExitToFreefallState,
    attemptExitToWallSlideState,
}

local function attemptExitAirborneState(stateMachine: StateMachine): boolean
    for _, check in ipairs(EXIT_CHECKS) do
        if check(stateMachine) then
            return true
        end
    end

    return false
end

local function attemptCutJumpEarly(stateMachine: StateMachine): ()
    local context = stateMachine.Context
    if context.InputController.IsHoldingJump or context:HasFlag(CUT_JUMP_FLAG) then
        return
    end

    if context.PhysicsResolver.Velocity.Y <= 0 then
        return
    end

    context:SetFlag(CUT_JUMP_FLAG)
    context.PhysicsResolver:SetRiseSpeedFraction(MovementConfig.JumpCutSpeedFraction)

    local timers = context.TimerUtility
    local remaining: number = timers:GetTimeRemaining(TimerID.JumpRise)
    timers:StartTimer(TimerID.JumpRise, math.min(remaining, MovementConfig.JumpCutDuration))
end

local function driveHorizontalMovement(stateMachine: StateMachine): ()
    local context = stateMachine.Context
    local moveDirection = context.InputController.MoveDirection
    local speed: number = if context:HasFlag(DASH_JUMP_FLAG) then MovementConfig.DashSpeed else MovementConfig.MoveSpeed
    context.PhysicsResolver:MoveInDirection(moveDirection, speed)
end

function AirborneState.OnStep(self: AirborneState, stateMachine: StateMachine, dt: number): ()
	if attemptExitAirborneState(stateMachine) then
        return
    end

    if self.Id == MovementStateID.Jump then
        attemptCutJumpEarly(stateMachine)
        attemptEndRise(stateMachine)
    end
    driveHorizontalMovement(stateMachine)
end

table.freeze(AirborneState)

return AirborneState
