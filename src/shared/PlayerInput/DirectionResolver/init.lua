--!strict
local DirectionResolver = {}
DirectionResolver.__index = DirectionResolver

local Direction = require(game:GetService("ReplicatedStorage").Data.Direction)
type Direction = Direction.Direction

type DirectionResolverData = {
    _currentDirection: Direction
}

export type DirectionResolver = typeof(setmetatable({} :: DirectionResolverData, DirectionResolver))

function DirectionResolver.new(): DirectionResolver
    local self = setmetatable({}, DirectionResolver)
    self._currentDirection = Direction.None
    return self :: DirectionResolver
end

function DirectionResolver.Resolve(self: DirectionResolver, isLeftHeld: boolean, isRightHeld: boolean): ()
    if isLeftHeld and isRightHeld then
        self._currentDirection = Direction.None
    elseif isLeftHeld then
        self._currentDirection = Direction.Left
    elseif isRightHeld then
        self._currentDirection = Direction.Right
    else
        self._currentDirection = Direction.None
    end
end

function DirectionResolver.GetDirection(self: DirectionResolver): Direction
    return self._currentDirection
end

function DirectionResolver.Destroy(self: DirectionResolver): ()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(DirectionResolver)
return DirectionResolver
