local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)
local GroundedBehavior = require(script.Parent.GroundedBehavior)

local WalkState = setmetatable({}, BaseState)
WalkState.__index = WalkState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type WalkState = BaseState

function WalkState.new(): WalkState
    local base = BaseState.new(MovementStateID.Walk) :: BaseState
    local self = setmetatable(base, WalkState)
    return self :: WalkState
end

local function attemptExitToIdleState(stateMachine: StateMachine): boolean
    local moveDirection = stateMachine.Context.PlayerInput:GetMoveDirection()
    local isPlayerMoving = moveDirection ~= Direction.None
    if isPlayerMoving then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
end

function WalkState.OnStep(self: WalkState, stateMachine: StateMachine, dt: number): ()
    if GroundedBehavior.AttemptExitToNonGroundedState(stateMachine) then
        return
    end

    GroundedBehavior.DrivePlayerMovement(stateMachine.Context)
    attemptExitToIdleState(stateMachine)
end

table.freeze(WalkState)

return WalkState
