--!strict
local FSMContext = {}
FSMContext.__index = FSMContext

local ParentDirectory = script.Parent
local PlayerInputFacade = require(game:GetService("ReplicatedStorage").PlayerInput.PlayerInputFacade)
local CollisionQuery = require(ParentDirectory.CollisionQuery)
local PhysicsResolver = require(ParentDirectory.PhysicsResolver)
local TimerUtility = require(ParentDirectory.TimerUtility)

type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type CollisionQuery = CollisionQuery.CollisionQuery
type PhysicsResolver = PhysicsResolver.PhysicsResolver
type TimerUtility = TimerUtility.TimerUtility

export type FSMContextDependencies = {
	PlayerInput: PlayerInputFacade,
	CollisionQuery: CollisionQuery,
	PhysicsResolver: PhysicsResolver,
	TimerUtility: TimerUtility?
}

export type FSMContext = typeof(setmetatable(
	{} :: {
		PlayerInput: PlayerInputFacade,
        CollisionQuery: CollisionQuery,
        PhysicsResolver: PhysicsResolver,
        TimerUtility: TimerUtility?,
		PreviousStateId: string?,
        _flags: { [string]: boolean }
	},
	{} :: typeof(FSMContext)
))

function FSMContext.new(deps: FSMContextDependencies): FSMContext
	assert(deps ~= nil)
	assert(deps.CollisionQuery)
	local self = setmetatable({
        PlayerInput = deps.PlayerInput,
        CollisionQuery = deps.CollisionQuery,
        PhysicsResolver = deps.PhysicsResolver,
        TimerUtility = deps.TimerUtility,
		PreviousStateId = nil,
        _flags =  {},
    }, FSMContext)
	
	return (self) :: FSMContext
end

function FSMContext.SetFlag(self: FSMContext, key: string): ()
	self._flags[key] = true
end

function FSMContext.HasFlag(self: FSMContext, key: string): boolean
	return self._flags[key] or false
end

function FSMContext.ClearFlag(self: FSMContext, key: string): ()
	self._flags[key] = nil
end

function FSMContext.ClearAllFlags(self: FSMContext): ()
	table.clear(self._flags)
end

function FSMContext.Destroy(self: FSMContext): ()
	self:ClearAllFlags()
end

table.freeze(FSMContext)

return FSMContext
