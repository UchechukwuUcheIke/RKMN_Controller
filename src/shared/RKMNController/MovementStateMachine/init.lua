--!strict
local ParentDirectory = script.Parent
local StateMachine = require(ParentDirectory.StateMachine)
local BaseState = require(ParentDirectory.BaseState)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FSMContext = require(ParentDirectory.FSMContext)
local Signal = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("goodsignal"))
local MovementStateID = require(ParentDirectory.MovementStateIDRegistry)
local MovementStateRegistry = require(ParentDirectory.MovementStateRegistry)


local MovementStateMachine = setmetatable({}, { __index = StateMachine })
MovementStateMachine.__index = MovementStateMachine

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
type Signal = typeof(Signal)
type FSMContext = FSMContext.FSMContext
type MovementStateID = MovementStateID.MovementStateID

export type MovementStateMachine = StateMachine

function MovementStateMachine.new(context: FSMContext): MovementStateMachine	
	assert(context)
	assert(context.CollisionQuery)
	local self = StateMachine.new(context) :: MovementStateMachine
	setmetatable(self, MovementStateMachine)
	self:SetStates(MovementStateRegistry)

	self:ChangeState(MovementStateID.Idle)
	
	return self
end

function MovementStateMachine.Destroy(self: MovementStateMachine): ()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end

	StateMachine.Destroy(self)
end

table.freeze(MovementStateMachine)

return MovementStateMachine
