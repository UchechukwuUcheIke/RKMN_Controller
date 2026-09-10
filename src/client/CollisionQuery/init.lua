--!strict
local Types = require(script.Parent.Types)

local CollisionQuery = {}
CollisionQuery.__index = CollisionQuery

local MovementConstantsModule = require(script.Parent.MovementConstants)

export type CollisionQuery = typeof(setmetatable({} :: Types.CollisionQueryData, CollisionQuery))

function CollisionQuery.new(characterModel: Model, movementConstants: MovementConstantsModule.MovementConstants): CollisionQuery
    local self = {}

    setmetatable(self , CollisionQuery)
    return self
end

return CollisionQuery