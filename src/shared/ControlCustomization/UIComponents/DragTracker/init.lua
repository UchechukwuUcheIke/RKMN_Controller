--!strict
local DragTracker = {}
DragTracker.__index = DragTracker

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)

type Signal = typeof(Signal)

type DragTrackerData = {
    _isEnabled: boolean,
    _dragInput: InputObject?,
    _dragConnections: {RBXScriptConnection},
    _targetConnection: RBXScriptConnection,
    Began: Signal,
    Moved: Signal,
    Ended: Signal
}

export type DragTracker = typeof(setmetatable({} :: DragTrackerData, DragTracker))

local function isPointerPress(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function getPointerPosition(input: InputObject): Vector2
    return Vector2.new(input.Position.X, input.Position.Y)
end

function DragTracker.new(target: GuiObject): DragTracker
    local self = setmetatable({}, DragTracker)

    self._isEnabled = true
    self._dragInput = nil
    self._dragConnections = {}
    self.Began = Signal.new()
    self.Moved = Signal.new()
    self.Ended = Signal.new()

    self._targetConnection = target.InputBegan:Connect(function(input: InputObject)
        self:_handleInputBegan(input)
    end)

    return self :: DragTracker
end

function DragTracker.IsDragging(self: DragTracker): boolean
    return self._dragInput ~= nil
end

function DragTracker.Enable(self: DragTracker): ()
    self._isEnabled = true
end

function DragTracker.Disable(self: DragTracker): ()
    self._isEnabled = false
    self:_endDrag()
end

function DragTracker._handleInputBegan(self: DragTracker, input: InputObject): ()
    if not self._isEnabled or self:IsDragging() or not isPointerPress(input) then
        return
    end

    self:_beginDrag(input)
end

function DragTracker._beginDrag(self: DragTracker, input: InputObject): ()
    self._dragInput = input

    table.insert(self._dragConnections, UserInputService.InputChanged:Connect(function(changedInput: InputObject)
        self:_handleInputChanged(changedInput)
    end))
    table.insert(self._dragConnections, UserInputService.InputEnded:Connect(function(endedInput: InputObject)
        self:_handleInputEnded(endedInput)
    end))

    self.Began:Fire(getPointerPosition(input))
end

function DragTracker._handleInputChanged(self: DragTracker, input: InputObject): ()
    if input.UserInputType == Enum.UserInputType.MouseMovement or input == self._dragInput then
        self.Moved:Fire(getPointerPosition(input))
    end
end

function DragTracker._handleInputEnded(self: DragTracker, input: InputObject): ()
    local dragInput = self._dragInput
    if not dragInput or input.UserInputType ~= dragInput.UserInputType then
        return
    end

    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if isTouch and input ~= dragInput then
        return
    end

    self:_endDrag()
end

function DragTracker._endDrag(self: DragTracker): ()
    if not self:IsDragging() then
        return
    end

    self:_disconnectDrag()
    self.Ended:Fire()
end

function DragTracker._disconnectDrag(self: DragTracker): ()
    for _, connection in ipairs(self._dragConnections) do
        connection:Disconnect()
    end
    table.clear(self._dragConnections)
    self._dragInput = nil
end

function DragTracker.Destroy(self: DragTracker): ()
    self:_disconnectDrag()
    self._targetConnection:Disconnect()
    self.Began:DisconnectAll()
    self.Moved:DisconnectAll()
    self.Ended:DisconnectAll()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(DragTracker)
return DragTracker
