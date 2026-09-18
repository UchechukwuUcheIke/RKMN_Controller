--!strict
local ParentDirectory = script.Parent
local Types = require(ParentDirectory:WaitForChild("Types"))

local BaseState = {}
BaseState.__index = BaseState

type StateMachine = Types.StateMachine

export type BaseState = typeof(setmetatable(
	{} :: { Id: string },
	{} :: typeof(BaseState)
))

function BaseState.new(id: string): BaseState
	local self = setmetatable({
		Id = id,
}, BaseState)
	return (self :: BaseState)
end

function BaseState.OnEnter(self: BaseState, stateMachine: StateMachine): () end
function BaseState.OnStep(self: BaseState, stateMachine: StateMachine, dt: number): () end
function BaseState.OnExit(self: BaseState, stateMachine: StateMachine): () end

table.freeze(BaseState)

return BaseState
