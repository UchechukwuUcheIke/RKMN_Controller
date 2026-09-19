local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local TimerID = require(RKMNControllerFolder.TimerIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)

local StunState = setmetatable({}, BaseState)
StunState.__index = StunState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type StunState = BaseState

function StunState.new(): StunState
    local base = BaseState.new(MovementStateID.Stun) :: BaseState
    local self = setmetatable(base, StunState)
	return self :: StunState
end

local function beginStun(stateMachine: StateMachine): ()
    stateMachine.Context.Input:SetEnabled(false)
    stateMachine.Context.Timers:StartTimer(TimerID.Stun)
end

function StunState.onEnter(self: StunState, stateMachine: StateMachine): ()
	beginStun(stateMachine)
end

local function attemptExitStunState(stateMachine: StateMachine, dt: number): ()
    local hasStunExpired: boolean = stateMachine.Context.Timers:IsComplete(TimerID.Stun)
    if hasStunExpired then
        stateMachine:ChangeState(MovementStateID.Idle)
    end
end

function StunState.OnStep(self: StunState, stateMachine: StateMachine, dt: number): ()
	attemptExitStunState(stateMachine, dt)
end

local function restorePlayerControls(stateMachine: StateMachine): ()
    stateMachine.Context.Input:SetEnabled(true)
end

function StunState.OnExit(self: StunState, stateMachine: StateMachine): ()
    restorePlayerControls(stateMachine)
end

table.freeze(StunState)

return StunState