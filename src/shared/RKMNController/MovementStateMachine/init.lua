--!strict
local ParentDirectory = script.Parent
local StateMachine = require(ParentDirectory.StateMachine)
local BaseState = require(ParentDirectory.BaseState)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FSMContext = require(ParentDirectory.FSMContext)
local Signal = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("goodsignal"))
local Types = require(ParentDirectory.Types)
local MovementStateID = require(ParentDirectory.MovementStateIDRegistry)
local MovementStateRegistry = require(ParentDirectory.MovementStateRegistry)


local MovementStateMachine = setmetatable({}, { __index = StateMachine })
MovementStateMachine.__index = MovementStateMachine

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
type Signal = typeof(Signal)
type FSMContext = FSMContext.FSMContext
type MovementStateID = MovementStateID.MovementStateID

export type MovementStateMachine = StateMachine & {
    _handleJumpPressed: (MovementStateMachine, FSMContext) -> (),
    _populateContextConnections: (MovementStateMachine, FSMContext) -> ()
}

function MovementStateMachine._handleOnJumpPressed(self: MovementStateMachine, context: FSMContext): ()
	if context.CollisionQuery:IsGrounded() or context.InputController.HasBufferedJump then
		context.InputController:ConsumeJumpBuffer()
		self:ChangeState(MovementStateID.Jump)
	end
end

function MovementStateMachine._populateContextConnections(self: MovementStateMachine, context: FSMContext): ()
	local connection = context.InputController.OnJumpPressed:Connect(function()
		self:_handleJumpPressed(context)
	end)

    table.insert(self._connections, connection)
end

function MovementStateMachine.new(context: FSMContext): MovementStateMachine	
	assert(context)
	assert(context.CollisionQuery)
	local self = StateMachine.new(context) :: MovementStateMachine
	setmetatable(self, MovementStateMachine)
	self:SetStates(MovementStateRegistry)
	
	self:_populateContextConnections(context)

	self:ChangeState(MovementStateID.Idle)
	
	return self
end

function MovementStateMachine.Destroy(self: MovementStateMachine): ()
	self:Destroy()
end

table.freeze(MovementStateMachine)

return MovementStateMachine
