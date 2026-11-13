--!strict
local RawInputObserver = {}
RawInputObserver.__index = RawInputObserver

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

type RawInputObserverData = {
    _hardwareInputSource: HardwareInputSource,
    _virtualInputSource: VirtualButtonInputSource,
    _connections: {Connection},
    OnActionBegan: Signal,
    OnActionEnded: Signal
}

export type RawInputObserver = typeof(setmetatable({} :: RawInputObserverData, RawInputObserver))

function RawInputObserver.new(hardwareInputSource: HardwareInputSource, virtualInputSource: VirtualButtonInputSource): RawInputObserver
    local self = setmetatable({}, RawInputObserver)

    self._hardwareInputSource = hardwareInputSource
    self._virtualInputSource = virtualInputSource
    self._connections = {}
    self.OnActionBegan = Signal.new()
    self.OnActionEnded = Signal.new()

    self:_bindActionEvents(hardwareInputSource)
    self:_bindActionEvents(virtualInputSource)

    return self :: RawInputObserver
end

function RawInputObserver._bindActionEvents(self: RawInputObserver, source: any): ()
    table.insert(self._connections, source.OnActionPressed:Connect(function(actionName: ActionID)
        self:_handleSourcePressed(actionName)
    end))

    table.insert(self._connections, source.OnActionReleased:Connect(function(actionName: ActionID)
        self:_handleSourceReleased(actionName)
    end))
end

function RawInputObserver.IsActionHeld(self: RawInputObserver, actionName: ActionID): boolean
    return (self._hardwareInputSource:IsActionHeld(actionName) 
        or self._virtualInputSource:IsActionHeld(actionName))
end

function RawInputObserver._countHolders(self: RawInputObserver, actionName: ActionID): number
    local holders = 0
    if self._hardwareInputSource:IsActionHeld(actionName) then
        holders += 1
    end
    if self._virtualInputSource:IsActionHeld(actionName) then
        holders += 1
    end
    return holders
end

function RawInputObserver._handleSourcePressed(self: RawInputObserver, actionName: ActionID): ()
    if self:_countHolders(actionName) == 1 then
        self.OnActionBegan:Fire(actionName)
    end
end

function RawInputObserver._handleSourceReleased(self: RawInputObserver, actionName: ActionID): ()
    if self:_countHolders(actionName) == 0 then
        self.OnActionEnded:Fire(actionName)
    end
end

function RawInputObserver.BindVirtualButton(self: RawInputObserver, actionName: ActionID, button: GuiButton): ()
    self._virtualInputSource:BindButton(actionName, button)
end

function RawInputObserver.ReleaseAllVirtual(self: RawInputObserver): ()
    self._virtualInputSource:ReleaseAll()
end

function RawInputObserver._unbindConnections(self: RawInputObserver): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    self.OnActionBegan:DisconnectAll()
    self.OnActionEnded:DisconnectAll()
end 

function RawInputObserver.Destroy(self: RawInputObserver): ()
    self:_unbindConnections()
    self._hardwareInputSource:Destroy()
    self._virtualInputSource:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(RawInputObserver)
return RawInputObserver
