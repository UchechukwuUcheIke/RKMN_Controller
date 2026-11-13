--!strict
local InputActionLog = {}
InputActionLog.__index = InputActionLog

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputActionMerger = require(PlayerInputFolder.InputActionMerger)
local InputPhase = require(script.InputPhase)
local LogEntry = require(script.LogEntry)
local RecordedEntry = require(script.RecordedEntry)

type ActionID = InputAction.ActionID
type InputPhase = InputPhase.InputPhase
type LogEntry = LogEntry.LogEntry
type RecordedEntry = RecordedEntry.RecordedEntry
type InputActionMerger = InputActionMerger.InputActionMerger
type Connection = { Disconnect: (self: any) -> () }

type InputActionLogData = {
    _entries: {RecordedEntry},
    _capacity: number,
    _maxAgeSeconds: number,
    _nextSlot: number,
    _count: number,
    _connections: {Connection}
}

export type InputActionLog = typeof(setmetatable({} :: InputActionLogData, InputActionLog))

local function validateArguments(capacity: number, maxAgeSeconds: number): ()
    assert(capacity >= 1, "An input log needs room for at least one entry")
    assert(maxAgeSeconds > 0, "An input log's maximum age must be above zero")
end

function InputActionLog.new(merger: InputActionMerger, capacity: number, maxAgeSeconds: number): InputActionLog
    validateArguments(capacity, maxAgeSeconds)

    local self = setmetatable({}, InputActionLog)

    self._entries = table.create(capacity)
    self._capacity = capacity
    self._maxAgeSeconds = maxAgeSeconds
    self._nextSlot = 1
    self._count = 0
    self._connections = {}

    table.insert(self._connections, merger.OnActionBegan:Connect(function(actionName: ActionID)
        self:_recordInputAction(actionName, InputPhase.Began)
    end))
    table.insert(self._connections, merger.OnActionEnded:Connect(function(actionName: ActionID)
        self:_recordInputAction(actionName, InputPhase.Ended)
    end))

    return self :: InputActionLog
end

function InputActionLog.CreateSnapshot(self: InputActionLog): {LogEntry}
    local currentTime = os.clock()
    local snapshot: {LogEntry} = {}
    local oldestSlot = if self._count < self._capacity then 1 else self._nextSlot

    for offset = 0, self._count - 1 do
        local slot = (oldestSlot - 1 + offset) % self._capacity + 1
        local entry = self._entries[slot]
        local secondsAgo = currentTime - entry.Time
        if secondsAgo <= self._maxAgeSeconds then
            table.insert(snapshot, LogEntry.new(entry.Action, entry.Phase, secondsAgo))
        end
    end

    return snapshot
end

function InputActionLog._recordInputAction(self: InputActionLog, actionName: ActionID, phase: InputPhase): ()
    self._entries[self._nextSlot] = RecordedEntry.new(actionName, phase)
    self._nextSlot = self._nextSlot % self._capacity + 1
    self._count = math.min(self._count + 1, self._capacity)
end

function InputActionLog.Destroy(self: InputActionLog): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    table.clear(self._entries)

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(InputActionLog)
return InputActionLog
