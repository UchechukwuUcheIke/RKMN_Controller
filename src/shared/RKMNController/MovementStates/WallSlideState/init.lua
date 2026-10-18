local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

local WallSlideState = setmetatable({}, BaseState)
WallSlideState.__index = WallSlideState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
type Direction = Direction.Direction
export type WallSlideState = BaseState

function WallSlideState.new(): WallSlideState
    local base = BaseState.new(MovementStateID.WallSlide) :: BaseState
    local self = setmetatable(base, WallSlideState)
	return self :: WallSlideState
end

function WallSlideState.OnEnter(self: WallSlideState, stateMachine: StateMachine): ()
    stateMachine.Context.PhysicsResolver:SetFallSpeedOverride(MovementConfig.WallSlideSpeed)
end

local function isHoldingTowardWall(stateMachine: StateMachine): boolean
    local context = stateMachine.Context
    local moveDirection: Direction = context.InputController.MoveDirection
    if moveDirection == Direction.None then
        return false
    end

    return context.CollisionQuery:CheckWallContact(moveDirection).Success
end

local function attemptExitToIdleState(stateMachine: StateMachine): boolean
    if not stateMachine.Context.CollisionQuery:IsGrounded() then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
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

local function attemptExitToFreefallState(stateMachine: StateMachine): boolean
    if isHoldingTowardWall(stateMachine) then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Freefall)
    return true
end

local EXIT_CHECKS = {
    attemptExitToIdleState,
    attemptExitToJumpState,
    attemptExitToFreefallState,
}

local function attemptExitWallSlideState(stateMachine: StateMachine): boolean
    for _, check in ipairs(EXIT_CHECKS) do
        if check(stateMachine) then
            return true
        end
    end

    return false
end

-- No horizontal velocity while sliding: a diagonal sweep into the wall would stall the vertical movement.
local function driveSlideMovement(stateMachine: StateMachine): ()
    stateMachine.Context.PhysicsResolver:MoveInDirection(Direction.None, 0)
end

function WallSlideState.OnStep(self: WallSlideState, stateMachine: StateMachine, dt: number): ()
    if attemptExitWallSlideState(stateMachine) then
        return
    end

    driveSlideMovement(stateMachine)
end

function WallSlideState.OnExit(self: WallSlideState, stateMachine: StateMachine): ()
    stateMachine.Context.PhysicsResolver:SetFallSpeedOverride(nil)
end

table.freeze(WallSlideState)

return WallSlideState
