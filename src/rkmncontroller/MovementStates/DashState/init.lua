local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local TimerID = require(RKMNControllerFolder.TimerIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)

local DashState = setmetatable({}, BaseState)
DashState.__index = DashState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine

export type DashState = BaseState

function DashState.new()
    local base = BaseState.new(MovementStateID.WallSlide) :: BaseState
    local self = setmetatable(base, DashState)
	return self :: DashState
end

function beginDash(stateMachine: StateMachine): ()
    stateMachine.Context.Timers:StartTimer(TimerID.Dash, MovementConfig.MaxDashDuration)
	stateMachine.Context.Physics:SetMaxSpeed(MovementConfig.DashSpeed)
	-- TOOD: Should get moved in certain direction as long as dash is acctive
	-- We need a way to hardcode the movement direction as long via InputController
end

function DashState.OnEnter(self: DashState, stateMachine: StateMachine): ()
	beginDash(stateMachine)
end

local function applyDashPhysics(stateMachine: StateMachine): ()
	-- Unsure if we should apply physics on step or just drive the physics mechanism via input
	-- Leaning more to doing it via physics directly
end

local function attemptExitDashState(stateMachine: StateMachine, dt: number): boolean
    local hasDashExpired: boolean = stateMachine.Context.Timers:IsComplete(TimerID.Dash)
    if hasDashExpired then
		stateMachine:ChangeState(MovementStateID.Idle)
		return true
	end

    local isGrounded: boolean = stateMachine.Context.CollisionQuery:IsGrounded()
	if not isGrounded then 		
        stateMachine:ChangeState(MovementStateID.Freefall)
        return true
    end

    return false
end

function DashState.OnStep(self: DashState, stateMachine: StateMachine, dt: number): ()
	local success: boolean = attemptExitDashState(stateMachine, dt)
    if success then
        return
    end

	applyDashPhysics(stateMachine)
end

function resetDashPhysics(stateMachine: StateMachine)
	stateMachine.Context.Physics:SetMaxSpeed(MovementConfig.WalkSpeed)
end

function DashState.OnExit(self: DashState, stateMachine: StateMachine)
	resetDashPhysics(stateMachine)
end

table.freeze(DashState)

return DashState
