local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
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

local function isMovingTowardWall(stateMachine: StateMachine): boolean
    local context = stateMachine.Context
    local moveDirection: Direction = context.PlayerInput:GetMoveDirection()
    local isPlayerMoving = moveDirection ~= Direction.None
    if not isPlayerMoving then
        return false
    end

    return context.CollisionQuery:CheckWallContact(moveDirection).Success
end

local function attemptExitToIdleState(stateMachine: StateMachine): boolean
    local isPlayerGrounded = stateMachine.Context.CollisionQuery:IsGrounded()
    if not isPlayerGrounded then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
end

local function attemptExitToJumpState(stateMachine: StateMachine): boolean
    local playerInput = stateMachine.Context.PlayerInput
    if not playerInput:HasBufferedJump() then
        return false
    end

    playerInput:ConsumeJumpBuffer()
    stateMachine:ChangeState(MovementStateID.Jump)
    return true
end

local function attemptExitToFreefallState(stateMachine: StateMachine): boolean
    if isMovingTowardWall(stateMachine) then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Freefall)
    return true
end

local function attemptExitWallSlideState(stateMachine: StateMachine): boolean
    local exitedSuccessfully = (attemptExitToIdleState(stateMachine) 
        or attemptExitToJumpState(stateMachine) 
        or attemptExitToFreefallState(stateMachine))

    return exitedSuccessfully
end

local function curtailHorizontalMovement(stateMachine: StateMachine): ()
    stateMachine.Context.PhysicsResolver:MoveInDirection(Direction.None, 0)
end

function WallSlideState.OnStep(self: WallSlideState, stateMachine: StateMachine, dt: number): ()
    if attemptExitWallSlideState(stateMachine) then
        return
    end

    curtailHorizontalMovement(stateMachine)
end

function WallSlideState.OnExit(self: WallSlideState, stateMachine: StateMachine): ()
    stateMachine.Context.PhysicsResolver:SetFallSpeedOverride(nil)
end

table.freeze(WallSlideState)

return WallSlideState
