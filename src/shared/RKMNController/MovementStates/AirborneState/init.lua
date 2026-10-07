local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)

local AirborneState = setmetatable({}, BaseState)
AirborneState.__index = AirborneState

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
export type AirborneState = BaseState & typeof(AirborneState)

function AirborneState.new(name: string): AirborneState
    local base = BaseState.new(MovementStateID.WallSlide) :: BaseState
    local self = setmetatable(base, AirborneState)
    self.IsDashJumping = false
    self.HasCutJump = false
	return self :: AirborneState
end

function AirborneState._resolveAirborneVariables(self: AirborneState, stateMachine: StateMachine): ()
    self.IsDashJumping = stateMachine.Context.PreviousStateID == MovementStateID.Dash
    self.HasCutJump = false
end

function AirborneState.OnEnter(self: AirborneState, stateMachine: StateMachine)
    self:_resolveAirborneVariables(stateMachine)
end

local function attemptExitAirborneState(stateMachine: StateMachine): boolean
    -- Maybe also check if they're moving?
    local isGrounded = stateMachine.Context.CollisionQuery:IsGrounded()
    if not isGrounded  then
        return false
    end

    stateMachine:ChangeState(MovementStateID.Idle)
    return true
end

local function attemptCutJumpEarly(stateMachine: StateMachine): ()
    -- TODO: 
    -- Get player's Y Velocity via physics
    -- Check if they've cut the jump and they are currently rising
    -- Reduce the vertical momentum
end

local function driveHorizontalMovement(stateMachine: StateMachine): ()
    -- Check if the player is dash jumping
    -- Get their relevant speed
    -- Move the player via the physics engine based on their speed
    --local speed: number = self.IsDashJumping and 

end

function AirborneState.OnStep(self: AirborneState, stateMachine: StateMachine, dt: number): ()
	attemptExitAirborneState(stateMachine)
    attemptCutJumpEarly(stateMachine)
    driveHorizontalMovement(stateMachine)
end

table.freeze(AirborneState)

return AirborneState