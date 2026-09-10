--!strict

local StateMachine = {}
StateMachine.__index = StateMachine

local Types = require(script.Parent.Types)

export type StateMachine = typeof(setmetatable({} :: Types.StateMachineData, StateMachine))


return StateMachine