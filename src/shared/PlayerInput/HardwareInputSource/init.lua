--!strict
local HardwareInputSource = {}
HardwareInputSource.__index = HardwareInputSource

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevPackages = ReplicatedStorage.DevPackages
local Signal = require(DevPackages:WaitForChild("goodsignal"))
local PlayerInputFolder = script.Parent
local InputAction = require(PlayerInputFolder.InputAction)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)
local InputMapper = require(PlayerInputFolder.InputMapper)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type InputBinding = InputSchemeTypes.InputBinding
type InputMapper = InputMapper.InputMapper
type Connection = { Disconnect: (self: any) -> () }

type HardwareInputSourceData = {
    _mapper: InputMapper,
    _connections: {RBXScriptConnection},
    _heldBindings: {[InputBinding]: ActionID},
    OnActionPressed: Signal,
    OnActionReleased: Signal
}

export type HardwareInputSource = typeof(setmetatable({} :: HardwareInputSourceData, HardwareInputSource))

function HardwareInputSource.new(mapper: InputMapper, userInputService: UserInputService): HardwareInputSource
    local self = setmetatable({}, HardwareInputSource)

    self._mapper = mapper
    self._connections = {}
    self._heldBindings = {}
    self.OnActionPressed = Signal.new()
    self.OnActionReleased = Signal.new()

    table.insert(self._connections, userInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        self:_handleInputBegan(input, gameProcessed)
    end))
    table.insert(self._connections, userInputService.InputEnded:Connect(function(input: InputObject)
        self:_handleInputEnded(input)
    end))
    table.insert(self._connections, userInputService.WindowFocusReleased:Connect(function()
        self:_handleWindowFocusReleased()
    end))

    return self :: HardwareInputSource
end

function HardwareInputSource._findMappedBinding(self: HardwareInputSource, input: InputObject): (InputBinding?, ActionID?)
    if input.KeyCode ~= Enum.KeyCode.None then
        local keyAction = self._mapper:GetActionForKey(input.KeyCode)
        if keyAction then
            return input.KeyCode, keyAction
        end
    end

    local typeAction = self._mapper:GetActionForKey(input.UserInputType)
    if typeAction then
        return input.UserInputType, typeAction
    end

    return nil, nil
end

function HardwareInputSource._findHeldBinding(self: HardwareInputSource, input: InputObject): InputBinding?
    if self._heldBindings[input.KeyCode] then
        return input.KeyCode
    elseif self._heldBindings[input.UserInputType] then
        return input.UserInputType
    end

    return nil
end

function HardwareInputSource.IsActionHeld(self: HardwareInputSource, actionName: ActionID): boolean
    for _, heldAction in pairs(self._heldBindings) do
        if heldAction == actionName then
            return true
        end
    end

    return false
end

function HardwareInputSource._handleInputBegan(self: HardwareInputSource, input: InputObject, gameProcessed: boolean): ()
    if gameProcessed then return end

    local binding, actionName = self:_findMappedBinding(input)
    if not binding or not actionName then
        return
    end

    local wasHeld = self:IsActionHeld(actionName)
    self._heldBindings[binding] = actionName
    if not wasHeld then
        self.OnActionPressed:Fire(actionName)
    end
end

function HardwareInputSource._handleInputEnded(self: HardwareInputSource, input: InputObject): ()
    local binding = self:_findHeldBinding(input)
    if not binding then
        return
    end

    local actionName = self._heldBindings[binding]
    self._heldBindings[binding] = nil
    if not self:IsActionHeld(actionName) then
        self.OnActionReleased:Fire(actionName)
    end
end

function HardwareInputSource._handleWindowFocusReleased(self: HardwareInputSource): ()
    local releasedActions: {[ActionID]: boolean} = {}
    for _, actionName in pairs(self._heldBindings) do
        releasedActions[actionName] = true
    end
    table.clear(self._heldBindings)

    for actionName in pairs(releasedActions) do
        self.OnActionReleased:Fire(actionName)
    end
end

function HardwareInputSource.Destroy(self: HardwareInputSource): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    self.OnActionPressed:DisconnectAll()
    self.OnActionReleased:DisconnectAll()
    table.clear(self._heldBindings)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(HardwareInputSource)
return HardwareInputSource
