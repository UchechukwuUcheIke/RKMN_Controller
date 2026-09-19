--!strict
local ParentDirectory = script.Parent
local BaseState = require(ParentDirectory.BaseState)
local FSMContext = require(ParentDirectory.FSMContext)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ParentDirectory.Types)
local Signal = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("goodsignal"))

local StateMachine = {}
StateMachine.__index = StateMachine

type BaseState = BaseState.BaseState
type FSMContext = FSMContext.FSMContext
type Signal = typeof(Signal)

export type StateMachine = Types.StateMachine

function StateMachine.new(context: FSMContext): StateMachine
	local self = setmetatable({}, StateMachine)
	
	self.Context = context
	self.States = {}
	
	self.CurrentStateId = nil
	self.CurrentState = nil
	
	self.OnStateChanged = Signal.new()
	
	return (self :: any) :: StateMachine
end

function StateMachine.RegisterState(self: StateMachine, id: string, state: BaseState): ()
	self.States[id] = (state :: any) :: Types.BaseState
end

function StateMachine.SetStates(self: StateMachine, states: { [string]: BaseState }): ()
	self.States = (states :: any) :: { [string]: Types.BaseState }
end

function StateMachine._exitCurrentState(self: StateMachine): ()
	if self.CurrentState == nil then
		return
	end

	self.Context.PreviousStateId = self.CurrentStateId
	if self.CurrentState.OnExit then
		self.CurrentState:OnExit(self)
	end
end

function StateMachine._enterNewState(self: StateMachine, newStateId: string, newState: BaseState): ()
	self.CurrentStateId = newStateId
	self.CurrentState = (newState :: any) :: Types.BaseState
	
	if self.CurrentState and self.CurrentState.OnEnter then
		self.CurrentState:OnEnter(self)
	end
end

function StateMachine.ChangeState(self: StateMachine, newStateId: string)
	local isAlreadyInState = self.CurrentStateId == newStateId
	if isAlreadyInState then 
		return 
	end
	
	local newState: Types.BaseState? = (self.States[newStateId] :: any) :: Types.BaseState?
	local newStateExists = (newState ~= nil)
	if not newStateExists then
		error("State not found: " .. newStateId) 
		return 
	end
	
	self:_exitCurrentState()
	self:_enterNewState(newStateId, newState :: Types.BaseState)
	self.OnStateChanged:Fire(newStateId)
end

function StateMachine.Update(self: StateMachine, dt: number): ()
	if self.CurrentState and self.CurrentState.OnStep then
		self.CurrentState:OnStep(self, dt) -- Pass FSM so it can call ChangeState
	end
end

function StateMachine.Destroy(self: StateMachine): ()
	self.OnStateChanged:Destroy()
	self.Context:Destroy()
	table.clear(self.States)
	setmetatable(self, nil)
end

table.freeze(StateMachine)

return StateMachine
