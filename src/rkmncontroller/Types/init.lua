--!strict

local Types = {}

export type BaseState = typeof(setmetatable(
	{} :: {
        Id: string,
        OnEnter: (self: BaseState, fsm: StateMachine) -> (),
        OnStep: (self: BaseState, fsm: StateMachine, dt: number) -> (),
        OnExit: (self: BaseState, fsm: StateMachine) -> ()
	},
	{}
))

export type StateMachine = {
	Context: any,
	States: { [string]: BaseState },
	CurrentStateId: string?,
	CurrentState: BaseState?,
	OnStateChanged: any,
	RegisterState: (self: StateMachine, id: string, state: BaseState) -> (),
	SetStates: (self: StateMachine, states: { [string]: BaseState }) -> (),
	ChangeState: (self: StateMachine, newStateId: string) -> (),
	Update: (self: StateMachine, dt: number) -> (),
	Destroy: (self: StateMachine) -> (),
    _enterNewState: (self: StateMachine, newStateId: string, newState: BaseState) -> (),
    _exitCurrentState: (self: StateMachine) -> (),
}



return Types