--!strict
local StateAnimationBinder = {}
StateAnimationBinder.__index = StateAnimationBinder
StateAnimationBinder.ClassName = "StateAnimationBinder"

local AnimationControllerFolder = script.Parent
local RKMNControllerFolder = AnimationControllerFolder.Parent
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local MovementAnimationSet = require(AnimationControllerFolder.MovementAnimationSet)
local AnimationTrackPlayer = require(AnimationControllerFolder.AnimationTrackPlayer)

type MovementStateMachine = MovementStateMachine.MovementStateMachine
type MovementAnimationSet = MovementAnimationSet.MovementAnimationSet
type AnimationTrackPlayer = AnimationTrackPlayer.AnimationTrackPlayer

type StateAnimationBinderData = {
	_animationSet: MovementAnimationSet,
	_trackPlayer: AnimationTrackPlayer,
	_connection: { Disconnect: (self: any) -> () }?,
}

type StateAnimationBinderPrototype = typeof({__index = StateAnimationBinder})

export type StateAnimationBinder = typeof(setmetatable(
	{} :: StateAnimationBinderData,
	{} :: StateAnimationBinderPrototype))

function StateAnimationBinder.new(
	movementFSM: MovementStateMachine,
	animationSet: MovementAnimationSet,
	trackPlayer: AnimationTrackPlayer): StateAnimationBinder

	local data: StateAnimationBinderData = {
		_animationSet = animationSet,
		_trackPlayer = trackPlayer,
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
	local entry = self._animationSet[stateId]
	if entry == nil or entry.AnimationId == "" then
		self._trackPlayer:Stop()
		return
	end

	self._trackPlayer:Play(entry)
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
