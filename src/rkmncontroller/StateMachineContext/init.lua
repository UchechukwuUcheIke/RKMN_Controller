--!strict
local FSMContext = {}
FSMContext.__index = FSMContext

local ParentDirectory = script.Parent
local InputController = require(ParentDirectory:WaitForChild("InputController"))
local CollisionQuery = require(ParentDirectory:WaitForChild("CollisionQuery"))
local PhysicsResolver = require(ParentDirectory:WaitForChild("PhysicsResolver"))
local TimerUtility = require(ParentDirectory:WaitForChild("TimerUtility"))

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
		PreviousStateID: string?,
        _flags: { [string]: boolean }
	},
	{} :: typeof(FSMContext)
))


function FSMContext.new(deps: FSMContextDependencies): FSMContext
	local self = setmetatable({
        InputController = deps.InputController,
	    CollisionQuery = deps.CollisionQuery,
	    PhysicsResolver = deps.PhysicsResolver,
	    TimerUtility = deps.TimerUtility or nil,
		PreviousStateID = nil,
        _flags = {}
    }, FSMContext)
	
	return (self :: FSMContext)
end

function FSMContext:SetFlag(key: string): ()
	self._flags[key] = true
end

function FSMContext:HasFlag(key: string): boolean
	return self._flags[key] or false
end

function FSMContext:ClearFlag(key: string): ()
	self._flags[key] = nil
end

function FSMContext:ClearAllFlags(): ()
	table.clear(self._flags)
end

function FSMContext.Destroy(self: FSMContext): ()
	self:ClearAllFlags()
	self.PreviousStateID = nil
end

table.freeze(FSMContext)

return FSMContext
