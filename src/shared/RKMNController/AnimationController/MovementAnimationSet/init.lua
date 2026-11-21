--!strict
local RKMNControllerFolder = script.Parent.Parent
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)

export type AnimationEntry = {
	AnimationId: string,
	IsLooped: boolean,
	Priority: Enum.AnimationPriority,
}

export type MovementAnimationSet = { [string]: AnimationEntry }

local function AnimationEntry(animationId: string, isLooped: boolean, priority: Enum.AnimationPriority): AnimationEntry
	return table.freeze({
		AnimationId = "",
		IsLooped = isLooped,
		Priority = priority,
	})
end

local MovementAnimationSet: MovementAnimationSet = {
	[MovementStateID.Idle] = AnimationEntry("18840245322", true, Enum.AnimationPriority.Idle),
	[MovementStateID.Walk] = AnimationEntry("18823831918", true, Enum.AnimationPriority.Movement),
	[MovementStateID.Jump] = AnimationEntry("8444234110", false, Enum.AnimationPriority.Movement),
	[MovementStateID.Freefall] = AnimationEntry("", true, Enum.AnimationPriority.Movement),
	[MovementStateID.WallSlide] = AnimationEntry("18854784306", true, Enum.AnimationPriority.Movement),
	[MovementStateID.Dash] = AnimationEntry("18823624728", false, Enum.AnimationPriority.Movement),
	[MovementStateID.Stun] = AnimationEntry("8545260081", false, Enum.AnimationPriority.Action),
}

return table.freeze(MovementAnimationSet)
