--!strict

local StateMachine = {}
StateMachine.__index = StateMachine

local StateDefinitionModule = require(script.Parent.StateDefinition)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("goodsignal"))

export type StateMachineData = {
    Context: {},
    States: {StateDefinitionModule.StateDefinition},
    CurrentStateId: string?,
    CurrentState: StateDefinitionModule.StateDefinition?,
    OnStateChanged: typeof(Signal)
}

export type StateMachine = typeof(setmetatable({} :: StateMachineData, StateMachine))

function StateMachine.new(initialStateId: string, context): StateMachine
    local self = setmetatable({}, StateMachine)

    self.Context = context or {}
    self.States = {}

    self.CurrentStateId = nil
    self.CurrentState = nil

    self.OnStateChanged = Signal.new()

    return self
end

function StateMachine:RegisterState(id: string, stateDefinition: StateDefinitionModule.StateDefinition): boolean
    if self.States[id] then
        warn("State id " .. " already exists")
        return false
    end

    self.States[id] = stateDefinition
    return true
end

function StateMachine:ChangeState(newStateId: string): boolean
    if self.CurrentStateId == newStateId then
        return true
    end

    local newState = self.States[newStateId]
    if not newState then
        warn("State " .. newStateId .. "not found")
        return false
    end

    local currentState: StateDefinitionModule.StateDefinition = self.CurrentState

    -- TODO: Complete


end

return StateMachine