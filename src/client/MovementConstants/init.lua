--!strict

local MovementConstants = {}
MovementConstants.__index = MovementConstants

local Types = require(script.Parent.Types)

export type MovementConstants = typeof(setmetatable({} :: Types.MovementConstantsData, MovementConstants))

function MovementConstants.new(characterModel: Model): MovementConstants
    local self = setmetatable({}, MovementConstants)

    return self
end

return MovementConstants