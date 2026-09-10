--!strict

local MovementConstants = {}
ActionStateMachine.__index = ActionStateMachine

type MovementConstantsData = {

}

export type MovementConstants = typeof(setmetatable({} :: MovementConstantsData, MovementConstants))


return MovementConstants