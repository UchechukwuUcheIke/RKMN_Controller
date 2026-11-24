--!strict
local StateMachineContext = {}
StateMachineContext.__index = StateMachineContext

local ParentDirectory = script.Parent
local PlayerInputFacade = require(game:GetService("ReplicatedStorage").PlayerInput.PlayerInputFacade)
local CollisionQueryFacade = require(ParentDirectory.CollisionQuery.CollisionQueryFacade)
local PhysicsResolverFacade = require(ParentDirectory.PhysicsResolver.PhysicsResolverFacade)
local TimerRegistry = require(ParentDirectory.TimerRegistry)

type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type CollisionQueryFacade = CollisionQueryFacade.CollisionQueryFacade
type PhysicsResolverFacade = PhysicsResolverFacade.PhysicsResolverFacade
type TimerRegistry = TimerRegistry.TimerRegistry

export type StateMachineContextDependencies = {
	PlayerInput: PlayerInputFacade,
	CollisionQuery: CollisionQueryFacade,
	PhysicsResolver: PhysicsResolverFacade,
	TimerRegistry: TimerRegistry?
}

export type StateMachineContext = typeof(setmetatable(
	{} :: {
		PlayerInput: PlayerInputFacade,
        CollisionQuery: CollisionQueryFacade,
        PhysicsResolver: PhysicsResolverFacade,
        TimerRegistry: TimerRegistry?,
		PreviousStateId: string?,
        _flags: { [string]: boolean }
	},
	{} :: typeof(StateMachineContext)
))

function StateMachineContext.new(deps: StateMachineContextDependencies): StateMachineContext
	assert(deps ~= nil)
	assert(deps.CollisionQuery)
	local self = setmetatable({
        PlayerInput = deps.PlayerInput,
        CollisionQuery = deps.CollisionQuery,
        PhysicsResolver = deps.PhysicsResolver,
        TimerRegistry = deps.TimerRegistry,
		PreviousStateId = nil,
        _flags =  {},
    }, StateMachineContext)
	
	return (self) :: StateMachineContext
end

function StateMachineContext.SetFlag(self: StateMachineContext, key: string): ()
	self._flags[key] = true
end

function StateMachineContext.HasFlag(self: StateMachineContext, key: string): boolean
	return self._flags[key] or false
end

function StateMachineContext.ClearFlag(self: StateMachineContext, key: string): ()
	self._flags[key] = nil
end

function StateMachineContext.ClearAllFlags(self: StateMachineContext): ()
	table.clear(self._flags)
end

function StateMachineContext.Destroy(self: StateMachineContext): ()
	self:ClearAllFlags()
end

table.freeze(StateMachineContext)

return StateMachineContext
