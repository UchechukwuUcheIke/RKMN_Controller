local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)
local GroundedBehavior = require(script.Parent.GroundedBehavior)

local IdleState = setmetatable({}, BaseState)
IdleState.__index = IdleState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type IdleState = BaseState

function IdleState.new(): IdleState
    local base = BaseState.new(MovementStateID.Idle) :: BaseState
    local self = setmetatable(base, IdleState)
    return self :: IdleState
end

local function attemptExitToWalkState(stateMachine: StateMachine): boolean
    local moveDirection = stateMachine.Context.PlayerInput:GetMoveDirection()
    local isPlayerMoving = moveDirection ~= Direction.None
    if not isPlayerMoving then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Walk)
    return true
end

function IdleState.OnStep(self: IdleState, stateMachine: StateMachine, dt: number): ()
    if GroundedBehavior.AttemptExitToNonGroundedState(stateMachine) then
        return
    end

    GroundedBehavior.DrivePlayerMovement(stateMachine.Context)
    attemptExitToWalkState(stateMachine)
end

function IdleState.OnExit(self: IdleState, stateMachine: StateMachine): ()
    GroundedBehavior.RestorePlayerControls(stateMachine.Context)
end

table.freeze(IdleState)

return IdleState
