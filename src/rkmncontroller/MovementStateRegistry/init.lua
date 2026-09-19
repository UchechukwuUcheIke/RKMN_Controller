local RKMNControllerFolder = script.Parent
local MovementStatesFolder = RKMNControllerFolder.MovementStates
local MovementStateID = require(RKMNControllerFolder.MovementStateIDRegistry)
local GroundedState = require(MovementStatesFolder.GroundedState)
local AirborneState = require(MovementStatesFolder.AirborneState)
local WallSlideState = require(MovementStatesFolder.WallSlideState)
local DashState = require(MovementStatesFolder.DashState)
local StunState = require(MovementStatesFolder.StunState)

local MovementStates = {
	[MovementStateID.Idle] = GroundedState.new(MovementStateID.Idle),
    [MovementStateID.Walk] = GroundedState.new(MovementStateID.Walk),
	[MovementStateID.Jump] = AirborneState.new(MovementStateID.Jump),
	[MovementStateID.Freefall] = AirborneState.new(MovementStateID.Freefall),
	[MovementStateID.Dash] = DashState.new(),
	[MovementStateID.WallSlide] = WallSlideState.new(),
	[MovementStateID.Stun] = StunState.new()
}

table.freeze(MovementStates)

return MovementStates