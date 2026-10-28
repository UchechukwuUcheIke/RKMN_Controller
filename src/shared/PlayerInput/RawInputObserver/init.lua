--!strict
local RawInputObserver = {}
RawInputObserver.__index = RawInputObserver

local UserInputService = game:GetService("UserInputService")
local Signal = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("goodsignal"))
local PlayerInputFolder = script.Parent
local InputAction = require(PlayerInputFolder.InputAction)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)
local InputMapper = require(PlayerInputFolder.InputMapper)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type InputBinding = InputSchemeTypes.InputBinding
type InputMapper = InputMapper.InputMapper
type Connection = { Disconnect: (self: any) -> () }

type RawInputObserverData = {
    _mapper: InputMapper,
    _connections: {Connection},
    _acceptedBindings: {[InputBinding]: ActionID},
    _virtualHolds: {[ActionID]: boolean},
    OnActionBegan: Signal,
    OnActionEnded: Signal
}

export type RawInputObserver = typeof(setmetatable({} :: RawInputObserverData, RawInputObserver))

local MOUSE_BUTTONS: {[Enum.UserInputType]: boolean} = {
    [Enum.UserInputType.MouseButton1] = true,
    [Enum.UserInputType.MouseButton2] = true,
    [Enum.UserInputType.MouseButton3] = true,
}

local PRIMARY_GAMEPAD = Enum.UserInputType.Gamepad1

function RawInputObserver.new(mapper: InputMapper): RawInputObserver
    local self = setmetatable({}, RawInputObserver)

    self._mapper = mapper
    self._connections = {}
    self._acceptedBindings = {}
    self._virtualHolds = {}
    self.OnActionBegan = Signal.new()
    self.OnActionEnded = Signal.new()

    self:_bindInputEvents()

    return self :: RawInputObserver
end

-- Which binding of this input is mapped to an action, and that action.
function RawInputObserver._findMappedBinding(self: RawInputObserver, input: InputObject): (InputBinding?, ActionID?)
    if input.KeyCode ~= Enum.KeyCode.Unknown then
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

function RawInputObserver._findAcceptedBinding(self: RawInputObserver, input: InputObject): InputBinding?
    if self._acceptedBindings[input.KeyCode] then
        return input.KeyCode
    elseif self._acceptedBindings[input.UserInputType] then
        return input.UserInputType
    end

    return nil
end

-- True while any accepted binding or on-screen button holds the action.
function RawInputObserver._isActionActive(self: RawInputObserver, actionName: ActionID): boolean
    if self._virtualHolds[actionName] then
        return true
    end

    for _, acceptedAction in pairs(self._acceptedBindings) do
        if acceptedAction == actionName then
            return true
        end
    end

    return false
end

function RawInputObserver._handleInputBegan(self: RawInputObserver, input: InputObject, gameProcessed: boolean): ()
    if gameProcessed then return end

    local binding, actionName = self:_findMappedBinding(input)
    if not binding or not actionName then
        return
    end

    local wasActive = self:_isActionActive(actionName)
    self._acceptedBindings[binding] = actionName
    if not wasActive then
        self.OnActionBegan:Fire(actionName)
    end
end

-- Releases are never dropped for gameProcessed, or a press accepted in-game would never end.
function RawInputObserver._handleInputEnded(self: RawInputObserver, input: InputObject): ()
    local binding = self:_findAcceptedBinding(input)
    if not binding then
        return
    end

    local actionName = self._acceptedBindings[binding]
    self._acceptedBindings[binding] = nil
    if not self:_isActionActive(actionName) then
        self.OnActionEnded:Fire(actionName)
    end
end

function RawInputObserver._bindInputEvents(self: RawInputObserver): ()
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gp)
        self:_handleInputBegan(input, gp)
    end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        self:_handleInputEnded(input)
    end))
end

local function isBindingDown(binding: InputBinding): boolean
    if binding.EnumType == Enum.KeyCode then
        local keyCode = binding :: Enum.KeyCode
        return UserInputService:IsKeyDown(keyCode) or UserInputService:IsGamepadButtonDown(PRIMARY_GAMEPAD, keyCode)
    end

    local inputType = binding :: Enum.UserInputType
    return MOUSE_BUTTONS[inputType] == true and UserInputService:IsMouseButtonPressed(inputType)
end

function RawInputObserver.IsActionHeld(self: RawInputObserver, actionName: ActionID): boolean
    if self._virtualHolds[actionName] then
        return true
    end

    local boundKeys = self._mapper:GetKeysForAction(actionName)
    if not boundKeys then
        return false
    end

    for binding in pairs(boundKeys) do
        if isBindingDown(binding) then
            return true
        end
    end

    return false
end

function RawInputObserver._pressVirtual(self: RawInputObserver, actionName: ActionID): ()
    if self:_isActionActive(actionName) then
        self._virtualHolds[actionName] = true
        return
    end

    self._virtualHolds[actionName] = true
    self.OnActionBegan:Fire(actionName)
end

function RawInputObserver._releaseVirtual(self: RawInputObserver, actionName: ActionID): ()
    if not self._virtualHolds[actionName] then
        return
    end

    self._virtualHolds[actionName] = nil
    if not self:_isActionActive(actionName) then
        self.OnActionEnded:Fire(actionName)
    end
end

-- For when the buttons stop being usable (hidden or destroyed) mid-hold and no release will arrive.
function RawInputObserver.ReleaseAllVirtual(self: RawInputObserver): ()
    for actionName in pairs(self._virtualHolds) do
        self:_releaseVirtual(actionName)
    end
end

local function isPointerPress(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

function RawInputObserver.BindVirtualButton(self: RawInputObserver, actionName: ActionID, button: GuiButton): ()
    table.insert(self._connections, button.InputBegan:Connect(function(input)
        if isPointerPress(input) then
            self:_pressVirtual(actionName)
        end
    end))

    table.insert(self._connections, button.InputEnded:Connect(function(input)
        if isPointerPress(input) then
            self:_releaseVirtual(actionName)
        end
    end))

    table.insert(self._connections, button.MouseLeave:Connect(function()
        self:_releaseVirtual(actionName)
    end))
end

function RawInputObserver._clearConnections(self: RawInputObserver): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function RawInputObserver.Destroy(self: RawInputObserver): ()
    self:_clearConnections()
    self.OnActionBegan:DisconnectAll()
    self.OnActionEnded:DisconnectAll()
    table.clear(self._acceptedBindings)
    table.clear(self._virtualHolds)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(RawInputObserver)
return RawInputObserver
