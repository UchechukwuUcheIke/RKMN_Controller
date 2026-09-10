--!strict
local MovementStateMachine = {}
MovementStateMachine.__index = MovementStateMachine

local Types = require(script.Parent.Types)
local InputControllerModule = require(script.Parent.InputController)
local CollisionQueryModule = require(script.Parent.CollisionQuery)

export type MovementStateMachine = typeof(setmetatable({} :: Types.MovementStateMachineData, MovementStateMachine))

function MovementStateMachine.new(InputController: InputControllerModule.InputController, CollisionQuery: CollisionQueryModule.CollisionQuery): MovementStateMachine
    local self = setmetatable({}, MovementStateMachine)

    self.IsEnabled = false
    self.MoveDirection = 0
    self.IsHoldingJump = false
    self.IsHoldingDash = false
    self.IsCharging = false
    self.HasBufferedJump = false
    self._connections = {}

    return self
end


return MovementStateMachine