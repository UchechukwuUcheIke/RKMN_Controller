--!strict

local PhysicsResolver = {}
PhysicsResolver.__index = PhysicsResolver

local Types = require(script.Parent.Types)
local MovementConstantsModule = require(script.Parent.MovementConstants)

export type PhysicsResolver = typeof(setmetatable({} :: Types.PhysicsResolverData, PhysicsResolver))

function PhysicsResolver.new(characterModel: Model, movementConstants: MovementConstantsModule.MovementConstants)
    local self = setmetatable({}, PhysicsResolver)
    return self
end
return PhysicsResolver