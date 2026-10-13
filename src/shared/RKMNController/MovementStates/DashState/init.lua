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
    local base = BaseState.new(MovementStateID.Dash) :: BaseState
    local self = setmetatable(base, DashState)
	return self :: DashState
end

function DashState.OnEnter(self: DashState, stateMachine: StateMachine): ()
	local context = stateMachine.Context
	context.TimerUtility:StartTimer(TimerID.Dash, MovementConfig.MaxDashDuration)
	context.CollisionQuery:SetLedgeGuard(true)
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

local function attemptExitToIdleState(stateMachine: StateMachine)
	local context = stateMachine.Context
	local lastSweep = context.CollisionQuery.LastSweepResolution
	local isBlocked: boolean = lastSweep ~= nil and (lastSweep.SurfaceHits.HitWall or lastSweep.SurfaceHits.HitLedge)
	local isDashFinished: boolean = context.TimerUtility:IsComplete(TimerID.Dash)
	local hasReleasedDash: boolean = not context.InputController.IsHoldingDash

	if isBlocked or isDashFinished or hasReleasedDash then
		stateMachine:ChangeState(MovementStateID.Idle)
		return true
	end

	return false
end

local function attemptExitToFreefallState(stateMachine: StateMachine): boolean
	local context = stateMachine.Context
	if not context.CollisionQuery:IsGrounded() then
		stateMachine:ChangeState(MovementStateID.Freefall)
		return true
	end

	return false
end

local EXIT_CHECKS = {
	attemptExitToFreefallState,
	attemptExitToJumpState,
	attemptExitToIdleState,
}

local function attemptExitDashState(stateMachine: StateMachine): boolean
	for _, check in ipairs(EXIT_CHECKS) do
		if check(stateMachine) then
			return true
		end
	end
	
	return false
end

local function driveDashMovement(stateMachine: StateMachine): ()
	local physicsResolver = stateMachine.Context.PhysicsResolver
	physicsResolver:MoveInDirection(physicsResolver.FacingDirection, MovementConfig.DashSpeed)
end

function DashState.OnStep(self: DashState, stateMachine: StateMachine, dt: number): ()
	if attemptExitDashState(stateMachine) then
		return
	end

	driveDashMovement(stateMachine)
end

function DashState.OnExit(self: DashState, stateMachine: StateMachine)
	local context = stateMachine.Context
	context.TimerUtility:Cancel(TimerID.Dash)
	context.CollisionQuery:SetLedgeGuard(false)
end

table.freeze(DashState)

return DashState
