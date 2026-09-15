--!strict

local AnimationController = {}
AnimationController.__index = AnimationController

local Types = require(script.Parent.Types)
local MovementStateMachineModule = require(script.Parent.MovementStateMachine)
local ActionStateMachineModule = require(script.Parent.ActionStateMachine)

export type AnimationController = typeof(setmetatable({} :: Types.AnimationControllerData, AnimationController))

function AnimationController.new(characterModel: Model, movementFSM: MovementStateMachineModule.MovementStateMachine, actionFSM: ActionStateMachineModule.ActionStateMachine): AnimationController
    local self = setmetatable({}, AnimationController)
    return self
end


return AnimationController