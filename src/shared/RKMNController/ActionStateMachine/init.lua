--!strict

local ActionStateMachine = {}
ActionStateMachine.__index = ActionStateMachine

local Types = require(script.Parent.Types)
local InputControllerModule = require(script.Parent.InputController)

export type ActionStateMachine = typeof(setmetatable({} :: Types.ActionStateMachineData, ActionStateMachine))

function ActionStateMachine.new(InputController: InputControllerModule.InputController): ActionStateMachine
    local self = setmetatable({}, ActionStateMachine)

    return self
end


return ActionStateMachine