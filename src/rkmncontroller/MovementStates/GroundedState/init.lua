local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)

local GroundedState = setmetatable({}, BaseState)
GroundedState.__index = GroundedState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type GroundedState = BaseState

function GroundedState.new(name: string): GroundedState
    local base = BaseState.new(MovementStateID.WallSlide) :: BaseState
    local self = setmetatable(base, GroundedState)
	return self :: GroundedState
end

local function attemptExitGroundedState(stateMachine: StateMachine): boolean
    local isGrounded: boolean = stateMachine.Context.CollisionQuery.IsGrounded()
    if not isGrounded then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
end

local function drivePlayerPhysics(stateMachine): ()
    --TODO: Get player speed
    -- Get player direction
    -- Move player in that direction
end

function GroundedState.OnStep(self: GroundedState, stateMachine: StateMachine, dt: number): ()
	local success: boolean = attemptExitGroundedState(stateMachine)
    if success then
        return
    end
    drivePlayerPhysics(stateMachine)
end

local function restorePlayerControls(stateMachine: StateMachine): ()
    stateMachine.Context.Input:SetEnabled(true)
end

function GroundedState.OnExit(self: GroundedState, stateMachine: StateMachine): ()
    restorePlayerControls(stateMachine)
end

table.freeze(GroundedState)

return GroundedState