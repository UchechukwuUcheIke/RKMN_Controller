--!strict
local Types = {}

export type BaseState = typeof(setmetatable(
	{} :: {
        Id: string
	},
	{} :: {
		__index: {
			OnEnter: (self: BaseState, fsm: StateMachine) -> (),
			OnStep: (self: BaseState, fsm: StateMachine, dt: number) -> (),
			OnExit: (self: BaseState, fsm: StateMachine) -> ()
		}
	}
))

export type StateChangedSignal = {
	Connect: (self: StateChangedSignal, handler: (newStateId: string, previousStateId: string?) -> ()) -> { Disconnect: (self: any) -> () },
	Fire: (self: StateChangedSignal, newStateId: string, previousStateId: string?) -> (),
	Destroy: (self: StateChangedSignal) -> (),
}

export type StateMachine = {
	Context: any,
	States: { [string]: BaseState },
	CurrentStateId: string?,
	CurrentState: BaseState?,
	OnStateChanged: StateChangedSignal,
	RegisterState: (self: StateMachine, id: string, state: BaseState) -> (),
	SetStates: (self: StateMachine, states: { [string]: BaseState }) -> (),
	ChangeState: (self: StateMachine, newStateId: string) -> (),
	Update: (self: StateMachine, dt: number) -> (),
	Destroy: (self: StateMachine) -> (),
    _enterNewState: (self: StateMachine, newStateId: string, newState: BaseState) -> (),
    _exitCurrentState: (self: StateMachine) -> (),
	_connections: {any},
}



return Types