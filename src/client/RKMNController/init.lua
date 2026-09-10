local RKMNController = {}
RKMNController.__index = RKMNController

local MovementConstants = require(script.Parent.MovementConstants)
local TimerUtility = require(script.Parent.TimerUtility)
local InputController = require(script.Parent.InputController)
local CollisionQuery = require(script.Parent.CollisionQuery)
local MovementStateMachine = require(script.Parent.MovementStateMachine)
local ActionStateMachine = require(script.Parent.ActionStateMachine)
local PhysicsResolver = require(script.Parent.PhysicsResolver)
local AnimationController = require(script.Parent.AnimationController)


return RKMNController