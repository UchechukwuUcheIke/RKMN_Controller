--!strict
local RKMNControllerFolder = script.Parent.Parent
local MovementStateID = require(RKMNControllerFolder.MovementStateIDs)

export type AnimationEntry = {
	AnimationId: string,
	IsLooped: boolean,
	Priority: Enum.AnimationPriority,
}

export type MovementAnimationSet = { [string]: AnimationEntry }

local function entry(isLooped: boolean, priority: Enum.AnimationPriority): AnimationEntry
	return table.freeze({
		AnimationId = "",
		IsLooped = isLooped,
		Priority = priority,
	})
end

local MovementAnimationSet: MovementAnimationSet = {
	[MovementStateID.Idle] = entry(true, Enum.AnimationPriority.Idle),
	[MovementStateID.Walk] = entry(true, Enum.AnimationPriority.Movement),
	[MovementStateID.Jump] = entry(false, Enum.AnimationPriority.Movement),
	[MovementStateID.Freefall] = entry(true, Enum.AnimationPriority.Movement),
	[MovementStateID.WallSlide] = entry(true, Enum.AnimationPriority.Movement),
	[MovementStateID.Dash] = entry(false, Enum.AnimationPriority.Movement),
	[MovementStateID.Stun] = entry(false, Enum.AnimationPriority.Action),
}

return table.freeze(MovementAnimationSet)
