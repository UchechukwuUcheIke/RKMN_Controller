--!strict

local StateMachine = {}
StateMachine.__index = StateMachine

export type StateMachineData = {

}

export type StateMachine = typeof(setmetatable({} :: StateMachineData, StateMachine))


return StateMachine