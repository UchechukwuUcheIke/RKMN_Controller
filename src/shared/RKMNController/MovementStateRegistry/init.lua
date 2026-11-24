local RKMNControllerFolder = script.Parent
local MovementStatesFolder = RKMNControllerFolder.MovementStates
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)
local GroundedState = require(MovementStatesFolder.GroundedState)
local JumpState = require(MovementStatesFolder.JumpState)
local FreefallState = require(MovementStatesFolder.FreefallState)
local WallSlideState = require(MovementStatesFolder.WallSlideState)
local DashState = require(MovementStatesFolder.DashState)
local StunState = require(MovementStatesFolder.StunState)

local MovementStates = {
	[MovementStateID.Idle] = GroundedState.new(MovementStateID.Idle),
    [MovementStateID.Walk] = GroundedState.new(MovementStateID.Walk),
	[MovementStateID.Jump] = JumpState.new(),
	[MovementStateID.Freefall] = FreefallState.new(),
	[MovementStateID.Dash] = DashState.new(),
	[MovementStateID.WallSlide] = WallSlideState.new(),
	[MovementStateID.Stun] = StunState.new()
}

table.freeze(MovementStates)

return MovementStates