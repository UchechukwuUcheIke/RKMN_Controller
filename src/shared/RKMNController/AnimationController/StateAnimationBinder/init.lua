--!strict
local StateAnimationBinder = {}
StateAnimationBinder.__index = StateAnimationBinder
StateAnimationBinder.ClassName = "StateAnimationBinder"

local AnimationControllerFolder = script.Parent
local RKMNControllerFolder = AnimationControllerFolder.Parent
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local MovementAnimationSet = require(AnimationControllerFolder.MovementAnimationSet)
local AnimationTrackPlayer = require(AnimationControllerFolder.AnimationTrackPlayer)
local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)

type MovementStateMachine = MovementStateMachine.MovementStateMachine
type MovementAnimationSet = MovementAnimationSet.MovementAnimationSet
type AnimationTrackPlayer = AnimationTrackPlayer.AnimationTrackPlayer
type Direction = Direction.Direction

type StateAnimationBinderData = {
	_animationSet: MovementAnimationSet,
	_trackPlayer: AnimationTrackPlayer,
	_getFacingDirection: () -> Direction,
	_currentStateId: string?,
	_playedFacingDirection: Direction,
	_connection: { Disconnect: (self: any) -> () }?,
}

type StateAnimationBinderPrototype = typeof({__index = StateAnimationBinder})

export type StateAnimationBinder = typeof(setmetatable(
	{} :: StateAnimationBinderData,
	{} :: StateAnimationBinderPrototype))

function StateAnimationBinder.new(
	movementFSM: MovementStateMachine,
	animationSet: MovementAnimationSet,
	trackPlayer: AnimationTrackPlayer,
	getFacingDirection: () -> Direction): StateAnimationBinder

	local data: StateAnimationBinderData = {
		_animationSet = animationSet,
		_trackPlayer = trackPlayer,
		_getFacingDirection = getFacingDirection,
		_currentStateId = nil,
		_playedFacingDirection = getFacingDirection(),
		_connection = nil,
	}
	local self = setmetatable(data, StateAnimationBinder)

	self._connection = movementFSM.OnStateChanged:Connect(function(newStateId: string)
		self:_playAnimationFor(newStateId)
	end)

	local currentStateId = movementFSM.CurrentStateId
	if currentStateId then
		self:_playAnimationFor(currentStateId)
	end

	return self
end

function StateAnimationBinder._playAnimationFor(self: StateAnimationBinder, stateId: string): ()
	local facingDirection = self._getFacingDirection()
	self._currentStateId = stateId
	self._playedFacingDirection = facingDirection

	local directionalEntry = self._animationSet[stateId]
	if directionalEntry == nil then
		self._trackPlayer:Stop()
		return
	end

	local entry = if facingDirection == Direction.Left then directionalEntry.Left else directionalEntry.Right
	if entry.AnimationId == "" then
		self._trackPlayer:Stop()
		return
	end

	self._trackPlayer:Play(entry)
end

function StateAnimationBinder.Update(self: StateAnimationBinder): ()
	local currentStateId = self._currentStateId
	if currentStateId == nil then
		return
	end

	if self._getFacingDirection() ~= self._playedFacingDirection then
		self:_playAnimationFor(currentStateId)
	end
end

function StateAnimationBinder._clearConnections(self: StateAnimationBinder): ()
	local connection = self._connection
	if connection then
		connection:Disconnect()
		self._connection = nil
	end
end

function StateAnimationBinder.Destroy(self: StateAnimationBinder): ()
	self:_clearConnections()
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(StateAnimationBinder)

return StateAnimationBinder
