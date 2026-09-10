--!strict

local StateMachine = {}
StateMachine.__index = StateMachine

type PhysicsResolverData = {

}

export type PhysicsResolver = typeof(setmetatable({} :: PhysicsResolverData, PhysicsResolver))


return StateMachine