--!strict
local FSMContext = {}
FSMContext.__index = FSMContext

local ParentDirectory = script.Parent
local InputController = require(ParentDirectory.InputController)
local CollisionQuery = require(ParentDirectory.CollisionQuery)
local PhysicsResolver = require(ParentDirectory.PhysicsResolver)
local TimerUtility = require(ParentDirectory.TimerUtility)

type InputController = InputController.InputController
type CollisionQuery = CollisionQuery.CollisionQuery
type PhysicsResolver = PhysicsResolver.PhysicsResolver
type TimerUtility = TimerUtility.TimerUtility

export type FSMContextDependencies = {
	InputController: InputController,
	CollisionQuery: CollisionQuery,
	PhysicsResolver: PhysicsResolver,
	TimerUtility: TimerUtility?
}

export type FSMContext = typeof(setmetatable(
	{} :: {
		InputController: InputController,
        CollisionQuery: CollisionQuery,
        PhysicsResolver: PhysicsResolver,
        TimerUtility: TimerUtility?,
        _flags: { [string]: boolean }
	},
	{} :: typeof(FSMContext)
))

function FSMContext.new(deps: FSMContextDependencies): FSMContext
	local self = setmetatable({
        InputController = deps.InputController,
        CollisionQuery = deps.CollisionQuery,
        PhysicsResolver = deps.PhysicsResolver,
        TimerUtility = deps.TimerUtility,
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
