--!strict
local ParentDirectory = script.Parent
local StateMachine = require(ParentDirectory.StateMachine)
local BaseState = require(ParentDirectory.BaseState)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FSMContext = require(ParentDirectory.FSMContext)
local Signal = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("goodsignal"))
local Types = require(ParentDirectory.Types)
local MovementStateID = require(ParentDirectory.MovementStateIDRegistry)

local MovementStateMachine = {}
MovementStateMachine.__index = MovementStateMachine

type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine
type Signal = typeof(Signal)
type FSMContext = FSMContext.FSMContext
type MovementStateID = MovementStateID.MovementStateID

export type MovementStateMachine = StateMachine & {
    _connections: {},
    _handleJumpPressed: (MovementStateMachine, FSMContext) -> (),
    _populateContextConnections: (MovementStateMachine, FSMContext) -> ()
}

function MovementStateMachine._handleOnJumpPressed(self: MovementStateMachine, context: FSMContext): ()
	if context.CollisionQuery:IsGrounded() or context.InputController.HasBufferedJump then
		context.InputController:ConsumeJumpBuffer()
		self:ChangeState(MovementStateID.Jump)
	end
end

-- Not a fan of this name
function MovementStateMachine._populateContextConnections(self: MovementStateMachine, context: FSMContext): ()
	local connection = context.InputController.OnJumpPressed:Connect(function()
		self:_handleJumpPressed(context)
	end)

    table.insert(self._connections, connection)
end

-- Would be worthwhile to define the states in a separate file, import them here and then just remove the states as a dependency
function MovementStateMachine.new(self: MovementStateMachine, context: FSMContext, states: {[string]: Types.BaseState}): MovementStateMachine	
	local stateMachine = StateMachine.new(context)
	stateMachine:SetStates(states)
	
	self:_populateContextConnections(context)

	stateMachine:ChangeState(MovementStateID.Idle)
	
	return stateMachine :: MovementStateMachine
end

function MovementStateMachine.Destroy(self: MovementStateMachine): ()
	self:Destroy()
end

table.freeze(MovementStateMachine)

return MovementStateMachine
