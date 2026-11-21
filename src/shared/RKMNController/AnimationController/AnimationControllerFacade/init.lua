--!strict
local AnimationControllerFacade = {}
AnimationControllerFacade.__index = AnimationControllerFacade
AnimationControllerFacade.ClassName = "AnimationControllerFacade"

local AnimationControllerFolder = script.Parent
local RKMNControllerFolder = AnimationControllerFolder.Parent
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolverFacade = require(RKMNControllerFolder.PhysicsResolver.PhysicsResolverFacade)
local MovementAnimationSet = require(AnimationControllerFolder.MovementAnimationSet)
local AnimationTrackPlayer = require(AnimationControllerFolder.AnimationTrackPlayer)
local StateAnimationBinder = require(AnimationControllerFolder.StateAnimationBinder)

type MovementStateMachine = MovementStateMachine.MovementStateMachine
type MovementAnimationSet = MovementAnimationSet.MovementAnimationSet
type AnimationEntry = MovementAnimationSet.AnimationEntry
type PhysicsResolverFacade = PhysicsResolverFacade.PhysicsResolverFacade
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

-- Every animation the set can ask for, so the track player can load them all up front.
local function listEntries(animationSet: MovementAnimationSet): { AnimationEntry }
	local entries = {}
	for _, directionalEntry in animationSet do
		table.insert(entries, directionalEntry.Left)
		table.insert(entries, directionalEntry.Right)
	end
	return entries
end

function AnimationControllerFacade.new(
	characterModel: Model,
	movementFSM: MovementStateMachine,
	physicsResolver: PhysicsResolverFacade,
		animationSet: MovementAnimationSet?): AnimationControllerFacade

	local resolvedAnimationSet = animationSet or MovementAnimationSet
	local animator = findOrCreateAnimator(characterModel)
	local trackPlayer = AnimationTrackPlayer.new(animator, listEntries(resolvedAnimationSet))
	local function getFacingDirection()
		return physicsResolver:GetFacingDirection()
	end
	local data: AnimationControllerFacadeData = {
		_trackPlayer = trackPlayer,
		_binder = StateAnimationBinder.new(
			movementFSM, resolvedAnimationSet, trackPlayer, getFacingDirection),
	}

	return setmetatable(data, AnimationControllerFacade)
end

function AnimationControllerFacade.Update(self: AnimationControllerFacade): ()
	self._binder:Update()
end

function AnimationControllerFacade.Destroy(self: AnimationControllerFacade): ()
	self._binder:Destroy()
	self._trackPlayer:Destroy()
end

table.freeze(AnimationControllerFacade)

return AnimationControllerFacade
