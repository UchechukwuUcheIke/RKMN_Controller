--!strict

local AnimationController = {}
AnimationController.__index = AnimationController

type AnimationControllerData = {

}

export type AnimationController = typeof(setmetatable({} :: AnimationControllerData, AnimationController))


return AnimationController