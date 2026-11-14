--!strict
local BugReportPresenter = {}
BugReportPresenter.__index = BugReportPresenter

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local BugReport = ReplicatedStorage.Telemetry.BugReport
local BugReportDraft = require(BugReport.BugReportDraft)
local Platform = require(BugReport.BugReportDraft.Platform)
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local BugReportSubmitStatus = require(BugReport.BugReportSubmitStatus)
local BugReportButton = require(BugReport.UserInterface.BugReportButton)
local BugReportScreen = require(BugReport.UserInterface.BugReportScreen)
local StringUtils = require(ReplicatedStorage.Utility.StringUtils)
local InputActionLog = require(ReplicatedStorage.Telemetry.InputActionLog)
local InputActionLogEntry = require(ReplicatedStorage.Telemetry.InputActionLog.InputActionLogEntry)
local DeviceDetector = require(ReplicatedStorage.PlayerInput.DeviceDetector)
local PlayerInputFacade = require(ReplicatedStorage.PlayerInput.PlayerInputFacade)

type BugReportDraft = BugReportDraft.BugReportDraft
type InputActionLogEntry = InputActionLogEntry.InputActionLogEntry
type Platform = Platform.Platform
type InputDevice = InputDevice.InputDevice
type BugReportSubmitStatus = BugReportSubmitStatus.BugReportSubmitStatus
type BugReportButton = BugReportButton.BugReportButton
type BugReportScreen = BugReportScreen.BugReportScreen
type InputActionLog = InputActionLog.InputActionLog
type DeviceDetector = DeviceDetector.DeviceDetector
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type Signal = typeof(Signal)
type Connection = { Disconnect: (self: any) -> () }

export type BugReportPresenterDependencies = {
    Button: BugReportButton,
    Screen: BugReportScreen,
    InputLog: InputActionLog,
    DeviceDetector: DeviceDetector,
    PlayerInput: PlayerInputFacade,
    GetPlatform: () -> Platform,
    Submit: (draft: BugReportDraft) -> string,
    Delay: (seconds: number, callback: () -> ()) -> ()
}

type BugReportPresenterData = {
    _button: BugReportButton,
    _screen: BugReportScreen,
    _inputLog: InputActionLog,
    _deviceDetector: DeviceDetector,
    _playerInput: PlayerInputFacade,
    _getPlatform: () -> Platform,
    _submit: (draft: BugReportDraft) -> string,
    _delay: (seconds: number, callback: () -> ()) -> (),

    _isOpen: boolean,
    _isOpenAllowed: boolean,
    _isSendingBugReport: boolean,
    _isDestroyed: boolean,
    _inputSnapshot: {InputActionLogEntry},
    _device: InputDevice,
    _platform: Platform,
    _connections: {Connection},

    IsOpenChanged: Signal
}

export type BugReportPresenter = typeof(setmetatable({} :: BugReportPresenterData, BugReportPresenter))

local SENT_MESSAGE_SECONDS = 1.5

local STATUS_MESSAGES: {[BugReportSubmitStatus]: string} = {
    [BugReportSubmitStatus.Sent] = "Report sent. Thank you!",
    [BugReportSubmitStatus.Cooldown] = "Please wait a little before sending another report.",
    [BugReportSubmitStatus.Invalid] = "That report could not be sent. Check the description and try again.",
    [BugReportSubmitStatus.Failed] = "The report could not be sent. Please try again later.",
}

local function validateDescription(description: string): string?
    local descriptionEmpty = description == ""
    if descriptionEmpty then
        return "Please describe the bug first."
    end

    local length = utf8.len(description)
    local hasOnlyValidCharacters = length == nil
    if hasOnlyValidCharacters then
        return "The description contains characters that cannot be sent."
    end
    if length > BugReportDraft.MAX_DESCRIPTION_LENGTH then
        return `The description is too long (limit {BugReportDraft.MAX_DESCRIPTION_LENGTH} characters).`
    end

    return nil
end

function BugReportPresenter.new(dependencies: BugReportPresenterDependencies): BugReportPresenter
    local self = setmetatable({}, BugReportPresenter)

    self._button = dependencies.Button
    self._screen = dependencies.Screen
    self._inputLog = dependencies.InputLog
    self._deviceDetector = dependencies.DeviceDetector
    self._playerInput = dependencies.PlayerInput
    self._getPlatform = dependencies.GetPlatform
    self._submit = dependencies.Submit
    self._delay = dependencies.Delay

    self._isOpen = false
    self._isOpenAllowed = true
    self._isSendingBugReport = false
    self._isDestroyed = false
    self._inputSnapshot = {}
    self._device = InputDevice.Unknown
    self._platform = Platform.Unknown
    self._connections = {}
    self.IsOpenChanged = Signal.new()

    return self :: BugReportPresenter
end

function BugReportPresenter._bindConnections(self: BugReportPresenter): ()
    table.insert(self._connections, self._button.Activated:Connect(function()
        self:Open()
    end))
    table.insert(self._connections, self._screen.OnSubmitRequested:Connect(function(description: string)
        self:_handleSubmitRequested(description)
    end))
    table.insert(self._connections, self._screen.OnCancelRequested:Connect(function()
        self:Close()
    end))
end

function BugReportPresenter.Enable(self: BugReportPresenter): ()
    local alreadyHasConnections = #self._connections > 0
    if alreadyHasConnections then
        return
    end

    self:_bindConnections()
end

function BugReportPresenter.Disable(self: BugReportPresenter): ()
    self:Close()

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function BugReportPresenter.IsOpen(self: BugReportPresenter): boolean
    return self._isOpen
end

function BugReportPresenter.SetOpenAllowed(self: BugReportPresenter, isAllowed: boolean): ()
    self._isOpenAllowed = isAllowed
end

function BugReportPresenter.SetEntryVisible(self: BugReportPresenter, isVisible: boolean): ()
    self._button:SetVisible(isVisible)
end

function BugReportPresenter.Open(self: BugReportPresenter): ()
    if self._isOpen or not self._isOpenAllowed then
        return
    end

    self._isOpen = true
    self._inputSnapshot = self._inputLog:CreateSnapshot()
    self._device = self._deviceDetector:GetCurrentDevice()
    self._platform = self._getPlatform()

    self._playerInput:SuspendGameplayInput()
    self._screen:Clear()
    self._screen:SetSending(false)
    self._screen:SetVisible(true)
    self.IsOpenChanged:Fire(true)
end

function BugReportPresenter.Close(self: BugReportPresenter): ()
    if not self._isOpen then
        return
    end

    self._isOpen = false
    self._inputSnapshot = {}
    self._screen:SetVisible(false)
    self._playerInput:ResumeGameplayInput()
    self.IsOpenChanged:Fire(false)
end

function BugReportPresenter._buildDraft(self: BugReportPresenter, description: string): BugReportDraft
    return BugReportDraft.new(description, self._platform, self._device, self._inputSnapshot)
end

function BugReportPresenter._handleSubmitRequested(self: BugReportPresenter, rawDescription: string): ()
    if self._isSendingBugReport then
        return
    end

    local description = StringUtils.TrimWhitespace(rawDescription)
    local problem = validateDescription(description)
    if problem then
        self._screen:SetStatus(problem)
        return
    end

    self._isSendingBugReport = true
    self._screen:SetSending(true)
    self._screen:SetStatus("Sending...")

    local status = self._submit(self:_buildDraft(description))

    -- The reply can arrive after this presenter has been torn down.
    if self._isDestroyed then
        return
    end
    self._isSendingBugReport = false
    self:_showResult(status)
end

function BugReportPresenter._showResult(self: BugReportPresenter, status: BugReportSubmitStatus): ()
    self._screen:SetStatus(STATUS_MESSAGES[status] or STATUS_MESSAGES[BugReportSubmitStatus.Failed])

    if status == BugReportSubmitStatus.Sent then
        self._delay(SENT_MESSAGE_SECONDS, function()
            self:_closeAfterSent()
        end)
    else
        self._screen:SetSending(false)
    end
end

function BugReportPresenter._closeAfterSent(self: BugReportPresenter): ()
    if not self._isDestroyed then
        self:Close()
    end
end

function BugReportPresenter.Destroy(self: BugReportPresenter): ()
    self:Disable()
    self._isDestroyed = true
    self._screen:Destroy()
    self._button:Destroy()
    self.IsOpenChanged:DisconnectAll()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(BugReportPresenter)
return BugReportPresenter
