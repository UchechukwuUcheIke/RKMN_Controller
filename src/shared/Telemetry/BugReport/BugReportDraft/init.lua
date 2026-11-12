--!strict
local BugReportDraft = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(script.Platform)
local InputDevice = require(ReplicatedStorage.Data.InputDevice)

export type Platform = Platform.Platform
export type InputDevice = InputDevice.InputDevice

-- Strings, because that is what crosses the network; the server checks them against the real enums.
export type InputLogEntry = {
    Action: string,
    Phase: string,
    SecondsAgo: number
}

export type BugReportDraft = {
    Description: string,
    Platform: Platform,
    InputDevice: InputDevice,
    InputLog: {InputLogEntry}
}

BugReportDraft.MAX_DESCRIPTION_LENGTH = 2000
BugReportDraft.MAX_INPUT_LOG_ENTRIES = 200
BugReportDraft.MAX_INPUT_LOG_AGE_SECONDS = 60

table.freeze(BugReportDraft)
return BugReportDraft
