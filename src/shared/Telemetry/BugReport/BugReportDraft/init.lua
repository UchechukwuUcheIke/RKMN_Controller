--!strict
local BugReportDraft = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(script.Platform)
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local InputActionLogEntry = require(ReplicatedStorage.Telemetry.InputActionLog.InputActionLogEntry)

type InputActionLogEntry = InputActionLogEntry.InputActionLogEntry
export type Platform = Platform.Platform
export type InputDevice = InputDevice.InputDevice

export type BugReportDraft = {
    Description: string,
    Platform: Platform,
    InputDevice: InputDevice,
    InputLog: {InputActionLogEntry}
}

BugReportDraft.MAX_DESCRIPTION_LENGTH = 2000
BugReportDraft.MAX_INPUT_LOG_ENTRIES = 200
BugReportDraft.MAX_INPUT_LOG_AGE_SECONDS = 60

function BugReportDraft.new(
    description: string,
    platform: Platform,
    inputDevice: InputDevice,
    inputLog: {InputActionLogEntry}
): BugReportDraft
    return table.freeze({
        Description = description,
        Platform = platform,
        InputDevice = inputDevice,
        InputLog = inputLog,
    })
end

table.freeze(BugReportDraft)
return BugReportDraft
