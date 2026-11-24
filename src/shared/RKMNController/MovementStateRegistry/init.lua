local RKMNControllerFolder = script.Parent
local MovementStatesFolder = RKMNControllerFolder.MovementStates
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local IdleState = require(MovementStatesFolder.IdleState)
local WalkState = require(MovementStatesFolder.WalkState)
local JumpState = require(MovementStatesFolder.JumpState)
local FreefallState = require(MovementStatesFolder.FreefallState)
local WallSlideState = require(MovementStatesFolder.WallSlideState)
local DashState = require(MovementStatesFolder.DashState)
local StunState = require(MovementStatesFolder.StunState)

local MovementStates = {
	[MovementStateID.Idle] = IdleState.new(),
	[MovementStateID.Walk] = WalkState.new(),
	[MovementStateID.Jump] = JumpState.new(),
	[MovementStateID.Freefall] = FreefallState.new(),
	[MovementStateID.Dash] = DashState.new(),
	[MovementStateID.WallSlide] = WallSlideState.new(),
	[MovementStateID.Stun] = StunState.new()
}

table.freeze(MovementStates)

return MovementStates