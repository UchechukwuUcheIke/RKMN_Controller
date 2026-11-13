--!strict
local InputActionMerger = {}
InputActionMerger.__index = InputActionMerger

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevPackages = ReplicatedStorage.DevPackages
local Signal = require(DevPackages:WaitForChild("goodsignal"))
local PlayerInputFolder = script.Parent
local InputAction = require(PlayerInputFolder.InputAction)
local HardwareInputSource = require(PlayerInputFolder.HardwareInputSource)
local VirtualButtonInputSource = require(PlayerInputFolder.VirtualButtonInputSource)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type HardwareInputSource = HardwareInputSource.HardwareInputSource
type VirtualButtonInputSource = VirtualButtonInputSource.VirtualButtonInputSource
type Connection = { Disconnect: (self: any) -> () }

type InputActionMergerData = {
    _hardwareInputSource: HardwareInputSource,
    _virtualInputSource: VirtualButtonInputSource,
    _connections: {Connection},
    OnActionBegan: Signal,
    OnActionEnded: Signal
}

export type InputActionMerger = typeof(setmetatable({} :: InputActionMergerData, InputActionMerger))

function InputActionMerger.new(hardwareInputSource: HardwareInputSource, virtualInputSource: VirtualButtonInputSource): InputActionMerger
    local self = setmetatable({}, InputActionMerger)

    self._hardwareInputSource = hardwareInputSource
    self._virtualInputSource = virtualInputSource
    self._connections = {}
    self.OnActionBegan = Signal.new()
    self.OnActionEnded = Signal.new()

    self:_bindActionEvents(hardwareInputSource)
    self:_bindActionEvents(virtualInputSource)

    return self :: InputActionMerger
end

function InputActionMerger._bindActionEvents(self: InputActionMerger, source: any): ()
    table.insert(self._connections, source.OnActionPressed:Connect(function(actionName: ActionID)
        self:_handleSourcePressed(actionName)
    end))

    table.insert(self._connections, source.OnActionReleased:Connect(function(actionName: ActionID)
        self:_handleSourceReleased(actionName)
    end))
end

function InputActionMerger.IsActionHeld(self: InputActionMerger, actionName: ActionID): boolean
    return (self._hardwareInputSource:IsActionHeld(actionName) 
        or self._virtualInputSource:IsActionHeld(actionName))
end

function InputActionMerger._countHolders(self: InputActionMerger, actionName: ActionID): number
    local holders = 0
    if self._hardwareInputSource:IsActionHeld(actionName) then
        holders += 1
    end
    if self._virtualInputSource:IsActionHeld(actionName) then
        holders += 1
    end
    return holders
end

function InputActionMerger._handleSourcePressed(self: InputActionMerger, actionName: ActionID): ()
    if self:_countHolders(actionName) == 1 then
        self.OnActionBegan:Fire(actionName)
    end
end

function InputActionMerger._handleSourceReleased(self: InputActionMerger, actionName: ActionID): ()
    if self:_countHolders(actionName) == 0 then
        self.OnActionEnded:Fire(actionName)
    end
end

function InputActionMerger.BindVirtualButton(self: InputActionMerger, actionName: ActionID, button: GuiButton): ()
    self._virtualInputSource:BindButton(actionName, button)
end

function InputActionMerger.ReleaseAllVirtual(self: InputActionMerger): ()
    self._virtualInputSource:ReleaseAll()
end

function InputActionMerger._unbindConnections(self: InputActionMerger): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    self.OnActionBegan:DisconnectAll()
    self.OnActionEnded:DisconnectAll()
end 

function InputActionMerger.Destroy(self: InputActionMerger): ()
    self:_unbindConnections()
    self._hardwareInputSource:Destroy()
    self._virtualInputSource:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(InputActionMerger)
return InputActionMerger
