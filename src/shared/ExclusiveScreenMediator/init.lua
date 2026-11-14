--!strict
local ExclusiveScreenMediator = {}
ExclusiveScreenMediator.__index = ExclusiveScreenMediator

type Connection = { Disconnect: (self: any) -> () }

export type ExclusiveScreen = {
    IsOpenChanged: { Connect: (self: any, callback: (isOpen: boolean) -> ()) -> Connection },
    IsOpen: (self: any) -> boolean,
    SetOpenAllowed: (self: any, isAllowed: boolean) -> ()
}

export type EntryPoint = {
    SetEntryVisible: (self: any, isVisible: boolean) -> ()
}

type ExclusiveScreenMediatorData = {
    _screens: {ExclusiveScreen},
    _entryPoints: {EntryPoint},
    _connections: {Connection}
}

export type ExclusiveScreenMediator = typeof(setmetatable({} :: ExclusiveScreenMediatorData, ExclusiveScreenMediator))

function ExclusiveScreenMediator.new(): ExclusiveScreenMediator
    local self = setmetatable({}, ExclusiveScreenMediator)

    self._screens = {}
    self._entryPoints = {}
    self._connections = {}

    return self :: ExclusiveScreenMediator
end

function ExclusiveScreenMediator.AddScreen(self: ExclusiveScreenMediator, screen: ExclusiveScreen): ()
    table.insert(self._screens, screen)
    table.insert(self._connections, screen.IsOpenChanged:Connect(function()
        self:_refresh()
    end))

    self:_refresh()
end

function ExclusiveScreenMediator.AddEntryPoint(self: ExclusiveScreenMediator, entryPoint: EntryPoint): ()
    table.insert(self._entryPoints, entryPoint)

    self:_refresh()
end

function ExclusiveScreenMediator._isAnyScreenOpen(self: ExclusiveScreenMediator): boolean
    for _, screen in ipairs(self._screens) do
        if screen:IsOpen() then
            return true
        end
    end
    return false
end

function ExclusiveScreenMediator._refresh(self: ExclusiveScreenMediator): ()
    local isFree = not self:_isAnyScreenOpen()

    for _, screen in ipairs(self._screens) do
        screen:SetOpenAllowed(isFree)
    end
    for _, entryPoint in ipairs(self._entryPoints) do
        entryPoint:SetEntryVisible(isFree)
    end
end

function ExclusiveScreenMediator.Destroy(self: ExclusiveScreenMediator): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    table.clear(self._screens)
    table.clear(self._entryPoints)

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ExclusiveScreenMediator)
return ExclusiveScreenMediator
