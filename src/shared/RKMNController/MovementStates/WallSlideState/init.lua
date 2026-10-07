local RKMNControllerFolder = script.Parent.Parent
local BaseState = require(RKMNControllerFolder.BaseState)
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local MovementConfig = require(RKMNControllerFolder.MovementConfig)
local Direction = require(RKMNControllerFolder.Direction)

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

local function beginWallSlide(stateMachine: StateMachine): ()
    stateMachine.Context.PhysicsResolver:SetGravityMultiplier(MovementConfig.WallSlideGravity)
end

function WallSlideState.OnEnter(self: WallSlideState, stateMachine: StateMachine)
	beginWallSlide(stateMachine)
end

local function checkIsMovingTowardsWall(stateMachine: StateMachine): boolean
    local movementDirection: Direction = stateMachine.Context.InputController.MovementDirection

    local isMovingTowardsWall = stateMachine.Context.CollisionQuery:GetWallContact(movementDirection)

    return isMovingTowardsWall
end

local function attemptEndWallSlide(stateMachine: StateMachine, dt: number): ()
    local isMovingTowardsWall: boolean = checkIsMovingTowardsWall(stateMachine)
    if not isMovingTowardsWall then
        stateMachine:ChangeState(MovementStateID.Idle)
    end
end

function WallSlideState.OnStep(self: WallSlideState, stateMachine: StateMachine, dt: number): ()
	attemptEndWallSlide(stateMachine, dt)
end

local function resetWallSlidePhysics(stateMachine: StateMachine): ()
    stateMachine.Context.Physics:SetGravity(MovementConfig.NormalGravity)
end

function WallSlideState.OnExit(self: WallSlideState, stateMachine: StateMachine)
	resetWallSlidePhysics(stateMachine)
end

table.freeze(WallSlideState)

return WallSlideState

