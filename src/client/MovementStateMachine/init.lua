--!strict

local MovementStateMachine = {}
MovementStateMachine.__index = MovementStateMachine

type MovementStateMachineData = {

}

export type MovementStateMachine = typeof(setmetatable({} :: MovementStateMachineData, MovementStateMachine))


return MovementStateMachine