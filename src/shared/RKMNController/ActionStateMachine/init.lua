--!strict

local ActionStateMachine = {}
ActionStateMachine.__index = ActionStateMachine

local Types = require(script.Parent.Types)
local PlayerInputFacadeModule = require(game:GetService("ReplicatedStorage").PlayerInput.PlayerInputFacade)

export type ActionStateMachine = typeof(setmetatable({} :: Types.ActionStateMachineData, ActionStateMachine))

function ActionStateMachine.new(PlayerInput: PlayerInputFacadeModule.PlayerInputFacade): ActionStateMachine
    local self = setmetatable({}, ActionStateMachine)

    return self
end


return ActionStateMachine