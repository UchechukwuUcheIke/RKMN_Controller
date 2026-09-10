--!strict

local CollisionQuery = {}
CollisionQuery.__index = CollisionQuery

type CollisionQueryData = {

}

export type CollisionQuery = typeof(setmetatable({} :: CollisionQueryData, CollisionQuery))


return CollisionQuery