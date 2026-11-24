local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local AirborneBehavior = require(script.Parent.AirborneBehavior)

local JumpState = setmetatable({}, BaseState)
JumpState.__index = JumpState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type JumpState = BaseState

function JumpState.new(): JumpState
    local base = BaseState.new(MovementStateID.Jump) :: BaseState
    local self = setmetatable(base, JumpState)
    return self :: JumpState
end

function JumpState.OnEnter(self: JumpState, stateMachine: StateMachine): ()
    local context = stateMachine.Context
    AirborneBehavior.RefreshDashJumpFlag(context)
    context.PhysicsResolver:ApplyJumpImpulse()
end

local function attemptExitToFreefallState(stateMachine: StateMachine): boolean
    local isPlayerRisingInAir = stateMachine.Context.PhysicsResolver:GetVelocity().Y > 0
    if isPlayerRisingInAir then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Freefall)
    return true
end

local function attemptExitJumpState(stateMachine: StateMachine): boolean
    local successfullyExited = (AirborneBehavior.AttemptExitToIdleState(stateMachine)
        or attemptExitToFreefallState(stateMachine))

    return successfullyExited
end

local function attemptCutJumpEarly(context): ()
    local isPlayerFallingInAir = context.PhysicsResolver:GetVelocity().Y <= 0
    if context.PlayerInput:IsHoldingJump() or isPlayerFallingInAir then
        return
    end

    context.PhysicsResolver:CutRise()
end

function JumpState.OnStep(self: JumpState, stateMachine: StateMachine, dt: number): ()
    if attemptExitJumpState(stateMachine) then
        return
    end

    local context = stateMachine.Context
    attemptCutJumpEarly(context)
    AirborneBehavior.DriveHorizontalMovement(context)
end

table.freeze(JumpState)

return JumpState
