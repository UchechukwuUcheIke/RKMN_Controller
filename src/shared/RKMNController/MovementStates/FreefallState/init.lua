local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local AirborneBehavior = require(script.Parent.AirborneBehavior)

local FreefallState = setmetatable({}, BaseState)
FreefallState.__index = FreefallState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type FreefallState = BaseState

function FreefallState.new(): FreefallState
    local base = BaseState.new(MovementStateID.Freefall) :: BaseState
    local self = setmetatable(base, FreefallState)
    return self :: FreefallState
end

function FreefallState.OnEnter(self: FreefallState, stateMachine: StateMachine): ()
    AirborneBehavior.RefreshDashJumpFlag(stateMachine.Context)
end

local function attemptExitFreefallState(stateMachine: StateMachine): boolean
    local successfullyExited = (AirborneBehavior.AttemptExitToIdleState(stateMachine)
        or AirborneBehavior.AttemptExitToWallSlideState(stateMachine))

    return successfullyExited
end

function FreefallState.OnStep(self: FreefallState, stateMachine: StateMachine, dt: number): ()
    if attemptExitFreefallState(stateMachine) then
        return
    end

    AirborneBehavior.DriveHorizontalMovement(stateMachine.Context)
end

table.freeze(FreefallState)

return FreefallState
