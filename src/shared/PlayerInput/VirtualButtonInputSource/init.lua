--!strict
local VirtualButtonInputSource = {}
VirtualButtonInputSource.__index = VirtualButtonInputSource

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevPackages = ReplicatedStorage.DevPackages
local Signal = require(DevPackages:WaitForChild("goodsignal"))
local PlayerInputFolder = script.Parent
local InputAction = require(PlayerInputFolder.InputAction)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID

type VirtualButtonInputSourceData = {
    _connections: {RBXScriptConnection},
    _heldActions: {[ActionID]: boolean},
    OnActionPressed: Signal,
    OnActionReleased: Signal
}

export type VirtualButtonInputSource = typeof(setmetatable({} :: VirtualButtonInputSourceData, VirtualButtonInputSource))

local function isPointerPress(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

function VirtualButtonInputSource.new(): VirtualButtonInputSource
    local self = setmetatable({}, VirtualButtonInputSource)

    self._connections = {}
    self._heldActions = {}
    self.OnActionPressed = Signal.new()
    self.OnActionReleased = Signal.new()

    return self :: VirtualButtonInputSource
end

function VirtualButtonInputSource.IsActionHeld(self: VirtualButtonInputSource, actionName: ActionID): boolean
    return self._heldActions[actionName] == true
end

function VirtualButtonInputSource._press(self: VirtualButtonInputSource, actionName: ActionID): ()
    if self._heldActions[actionName] then
        return
    end

    self._heldActions[actionName] = true
    self.OnActionPressed:Fire(actionName)
end

function VirtualButtonInputSource._release(self: VirtualButtonInputSource, actionName: ActionID): ()
    if not self._heldActions[actionName] then
        return
    end

    self._heldActions[actionName] = nil
    self.OnActionReleased:Fire(actionName)
end

function VirtualButtonInputSource.BindButton(self: VirtualButtonInputSource, actionName: ActionID, button: GuiButton): ()
    table.insert(self._connections, button.InputBegan:Connect(function(input: InputObject)
        if isPointerPress(input) then
            self:_press(actionName)
        end
    end))

    table.insert(self._connections, button.InputEnded:Connect(function(input: InputObject)
        if isPointerPress(input) then
            self:_release(actionName)
        end
    end))

    table.insert(self._connections, button.MouseLeave:Connect(function()
        self:_release(actionName)
    end))
end

function VirtualButtonInputSource.ReleaseAll(self: VirtualButtonInputSource): ()
    for actionName in pairs(self._heldActions) do
        self:_release(actionName)
    end
end

function VirtualButtonInputSource._unbindConnections(self: VirtualButtonInputSource): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    self.OnActionPressed:DisconnectAll()
    self.OnActionReleased:DisconnectAll()
end

function VirtualButtonInputSource.Destroy(self: VirtualButtonInputSource): ()
    self:_unbindConnections()
    table.clear(self._heldActions)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(VirtualButtonInputSource)
return VirtualButtonInputSource
