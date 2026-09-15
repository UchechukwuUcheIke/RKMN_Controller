local StateDefinition = {}
StateDefinition.__index = StateDefinition

type StateDefinitionData = {
    Id: string
}

export type StateDefinition = typeof(setmetatable({} :: StateDefinitionData, StateDefinition))


function StateDefinition.new(id: string): StateDefinition
    local self = setmetatable({}, StateDefinition)
    self.Id = id
    return self
end

function StateDefinition:OnEnter(fsm): ()
    return
end

function StateDefinition:OnStep(fsm, dt): ()
    return
end

function StateDefinition:OnExit(fsm): ()
    return
end

return StateDefinition