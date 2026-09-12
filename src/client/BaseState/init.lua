local BaseState = {}
BaseState.__index = BaseState

type BaseStateData = {

}

export type BaseState = typeof(setmetatable({} :: BaseStateData, BaseState))


function BaseState.new(id: string): BaseState
    local self = setmetatable({}, BaseState)
    self.Id = id
    return self
end

function BaseState:OnEnter(fsm): ()
    return
end

function BaseState:OnStep(fsm, dt): ()
    return
end

function BaseState:OnExit(fsm): ()
    return
end