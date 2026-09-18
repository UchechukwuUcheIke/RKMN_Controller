--!strict
local ParentDirectory = script.Parent
local StateMachine = require(ParentDirectory:WaitForChild("StateMachine"))

local BaseState = {}
BaseState.__index = BaseState

type StateMachine = StateMachine.StateMachine

export type State = typeof(setmetatable(
	{} :: {
        Id: string,
        OnEnter: (self: State, fsm: StateMachine) -> (),
        OnStep: (self: State, fsm: StateMachine, dt: number) -> (),
        OnExit: (self: State, fsm: StateMachine) -> ()
	},
	{} :: typeof(BaseState)
))



function BaseState.new(id: string): State
	local self = setmetatable({
		Id = id,
}, BaseState)
	return (self) :: State
end

function BaseState.OnEnter(self: State, fsm: StateMachine): () end
function BaseState.OnStep(self: State, fsm: StateMachine, dt: number): () end
function BaseState.OnExit(self: State, fsm: StateMachine): () end

table.freeze(BaseState)

return BaseState
