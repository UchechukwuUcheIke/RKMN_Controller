--!strict
local ControlPreferenceReporter = {}
ControlPreferenceReporter.__index = ControlPreferenceReporter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local ControlProfile = require(ReplicatedStorage.PlayerInput.ControlProfile)
local TouchLayoutProfile = require(ReplicatedStorage.TouchGamepad.TouchLayoutProfile)
local ControlPreferenceReport = require(script.Parent.ControlPreferenceReport)

type InputDevice = InputDevice.InputDevice
type ControlProfile = ControlProfile.ControlProfile
type TouchLayoutProfile = TouchLayoutProfile.TouchLayoutProfile
type ControlPreferenceReport = ControlPreferenceReport.ControlPreferenceReport
type Connection = { Disconnect: (self: any) -> () }

export type EditingScreen = {
    IsOpenChanged: { Connect: (self: any, callback: (isOpen: boolean) -> ()) -> Connection }
}

export type ControlPreferenceReporterDependencies = {
    ControlProfile: ControlProfile,
    TouchLayoutProfile: TouchLayoutProfile,
    EditingScreens: {EditingScreen},
    Submit: (report: ControlPreferenceReport) -> ()
}

type ControlPreferenceReporterData = {
    _controlProfile: ControlProfile,
    _touchLayoutProfile: TouchLayoutProfile,
    _submit: (report: ControlPreferenceReport) -> (),

    _editedDevices: {[InputDevice]: boolean},
    _hasEditedTouchLayout: boolean,
    _connections: {Connection}
}

export type ControlPreferenceReporter = typeof(setmetatable({} :: ControlPreferenceReporterData, ControlPreferenceReporter))

function ControlPreferenceReporter.new(dependencies: ControlPreferenceReporterDependencies): ControlPreferenceReporter
    local self = setmetatable({}, ControlPreferenceReporter)

    self._controlProfile = dependencies.ControlProfile
    self._touchLayoutProfile = dependencies.TouchLayoutProfile
    self._submit = dependencies.Submit

    self._editedDevices = {}
    self._hasEditedTouchLayout = false
    self._connections = {}

    self:_bindConnections(dependencies.EditingScreens)

    return self :: ControlPreferenceReporter
end

function ControlPreferenceReporter._bindConnections(self: ControlPreferenceReporter, editingScreens: {EditingScreen}): ()
    table.insert(self._connections, self._controlProfile.SchemeChanged:Connect(function(device: InputDevice)
        self._editedDevices[device] = true
    end))
 
    table.insert(self._connections, self._touchLayoutProfile.LayoutChanged:Connect(function()
        self._hasEditedTouchLayout = true
    end))

    for _, screen in ipairs(editingScreens) do
        table.insert(self._connections, screen.IsOpenChanged:Connect(function(isOpen: boolean)
            if not isOpen then
                self:_reportEditedControls()
                self:_clearEditHistory()
            end
        end))
    end
end

function ControlPreferenceReporter._reportEditedControls(self: ControlPreferenceReporter): ()
    local editedDevices = self._editedDevices
    local hasEditedTouchLayout = self._hasEditedTouchLayout

    for device in pairs(editedDevices) do
        if device ~= InputDevice.Touch then
            self._submit(ControlPreferenceReport.FromInputScheme(device, self._controlProfile:GetScheme(device)))
        end
    end

    if hasEditedTouchLayout then
        self._submit(ControlPreferenceReport.FromTouchLayout(self._touchLayoutProfile:GetLayout()))
    end
end

function ControlPreferenceReporter._clearEditHistory(self: ControlPreferenceReporter): ()
    self._editedDevices = {}
    self._hasEditedTouchLayout = false
end

function ControlPreferenceReporter.Destroy(self: ControlPreferenceReporter): ()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    table.clear(self._editedDevices)

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ControlPreferenceReporter)
return ControlPreferenceReporter
