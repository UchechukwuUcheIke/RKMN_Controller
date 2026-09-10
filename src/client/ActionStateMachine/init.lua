--!strict

local ActionStateMachine = {}
ActionStateMachine.__index = ActionStateMachine

type ActionStateMachineData = {

}

export type ActionStateMachine = typeof(setmetatable({} :: ActionStateMachineData, ActionStateMachine))


return ActionStateMachine