local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)
local TimerID = require(RKMNControllerFolder.TimerIDRegistry)

local AirborneState = setmetatable({}, BaseState)
AirborneState.__index = AirborneState

-- Stored on the context rather than the state: state instances are shared by every controller.
local CUT_JUMP_FLAG = "HasCutJump"

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type AirborneState = BaseState & typeof(AirborneState)

function AirborneState.new(name: string): AirborneState
    local base = BaseState.new(name) :: BaseState
    local self = setmetatable(base, AirborneState)
    self.IsDashJumping = false
	return self :: AirborneState
end

function AirborneState._resolveAirborneVariables(self: AirborneState, stateMachine: StateMachine): ()
    self.IsDashJumping = stateMachine.Context.PreviousStateId == MovementStateID.Dash
    stateMachine.Context:ClearFlag(CUT_JUMP_FLAG)
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

local function attemptExitAirborneState(stateMachine: StateMachine): boolean
    local context = stateMachine.Context
    -- The grounded flag is stale on the first step of a jump, so ignore it while still rising.
    local isRising: boolean = context.PhysicsResolver.Velocity.Y > 0
    if isRising or not context.CollisionQuery:IsGrounded() then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
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
    context.PhysicsResolver:MoveInDirection(moveDirection, MovementConfig.MoveSpeed)
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
