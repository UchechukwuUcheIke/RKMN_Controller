--!strict
local RKMNControllerFolder = script.Parent.Parent
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)

export type AnimationEntry = {
	AnimationId: string,
	IsLooped: boolean,
	Priority: Enum.AnimationPriority,
}

export type DirectionalAnimationEntry = {
	Left: AnimationEntry,
	Right: AnimationEntry,
}

export type MovementAnimationSet = { [string]: DirectionalAnimationEntry }

local function toAssetUri(animationId: string): string
	return if animationId == "" then "" else "rbxassetid://" .. animationId
end

local function AnimationEntry(animationId: string, isLooped: boolean, priority: Enum.AnimationPriority): AnimationEntry
	return table.freeze({
		AnimationId = toAssetUri(animationId),
		IsLooped = isLooped,
		Priority = priority,
	})
end

local function DirectionalEntry(
	leftAnimationId: string,
	rightAnimationId: string,
	isLooped: boolean,
	priority: Enum.AnimationPriority): DirectionalAnimationEntry

	return table.freeze({
		Left = AnimationEntry(leftAnimationId, isLooped, priority),
		Right = AnimationEntry(rightAnimationId, isLooped, priority),
	})
end

local MovementAnimationSet: MovementAnimationSet = {
	[MovementStateID.Idle] = DirectionalEntry("18840245322", "18840164138", true, Enum.AnimationPriority.Idle),
	[MovementStateID.Walk] = DirectionalEntry("18823831918", "18823802174", true, Enum.AnimationPriority.Movement),
	[MovementStateID.Jump] = DirectionalEntry("88089763069699", "84414425115244", false, Enum.AnimationPriority.Movement),
	[MovementStateID.Freefall] = DirectionalEntry("135811356098307", "135811356098307", true, Enum.AnimationPriority.Movement),
	[MovementStateID.WallSlide] = DirectionalEntry("18854784306", "18854747242", true, Enum.AnimationPriority.Movement),
	[MovementStateID.Dash] = DirectionalEntry("18824133124", "18824086561", false, Enum.AnimationPriority.Movement),
	[MovementStateID.Stun] = DirectionalEntry("8545260081", "8545226281", false, Enum.AnimationPriority.Action),
}

return table.freeze(MovementAnimationSet)
