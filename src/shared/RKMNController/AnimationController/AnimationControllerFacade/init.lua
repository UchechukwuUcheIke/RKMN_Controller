--!strict
local AnimationControllerFacade = {}
AnimationControllerFacade.__index = AnimationControllerFacade
AnimationControllerFacade.ClassName = "AnimationControllerFacade"

local AnimationControllerFolder = script.Parent
local RKMNControllerFolder = AnimationControllerFolder.Parent
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local MovementAnimationSet = require(AnimationControllerFolder.MovementAnimationSet)
local AnimationTrackPlayer = require(AnimationControllerFolder.AnimationTrackPlayer)
local StateAnimationBinder = require(AnimationControllerFolder.StateAnimationBinder)

type MovementStateMachine = MovementStateMachine.MovementStateMachine
type MovementAnimationSet = MovementAnimationSet.MovementAnimationSet
type AnimationTrackPlayer = AnimationTrackPlayer.AnimationTrackPlayer
type StateAnimationBinder = StateAnimationBinder.StateAnimationBinder

type AnimationControllerFacadeData = {
	_trackPlayer: AnimationTrackPlayer,
	_binder: StateAnimationBinder,
}

type AnimationControllerFacadePrototype = typeof({__index = AnimationControllerFacade})

export type AnimationControllerFacade = typeof(setmetatable(
	{} :: AnimationControllerFacadeData,
	{} :: AnimationControllerFacadePrototype))

local function findOrCreateAnimator(characterModel: Model): Animator
	local humanoid = characterModel:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "CharacterModel must have a Humanoid before AnimationControllerFacade.new()")

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end

	local newAnimator = Instance.new("Animator")
	newAnimator.Parent = humanoid
	return newAnimator
end

function AnimationControllerFacade.new(
	characterModel: Model,
	movementFSM: MovementStateMachine,
	animationSet: MovementAnimationSet?): AnimationControllerFacade

	local animator = findOrCreateAnimator(characterModel)
	local trackPlayer = AnimationTrackPlayer.new(animator)
	local data: AnimationControllerFacadeData = {
		_trackPlayer = trackPlayer,
		_binder = StateAnimationBinder.new(movementFSM, animationSet or MovementAnimationSet, trackPlayer),
	}

	return setmetatable(data, AnimationControllerFacade)
end

function AnimationControllerFacade.Destroy(self: AnimationControllerFacade): ()
	self._binder:Destroy()
	self._trackPlayer:Destroy()
end

table.freeze(AnimationControllerFacade)

return AnimationControllerFacade
