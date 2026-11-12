--!strict
local BugReportValidator = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BugReportDraft = require(ReplicatedStorage.Telemetry.BugReport.BugReportDraft)
local Platform = require(ReplicatedStorage.Telemetry.BugReport.BugReportDraft.Platform)
local InputDevice = require(ReplicatedStorage.Telemetry.BugReport.BugReportDraft.InputDevice)
local StringEnum = require(ReplicatedStorage.Utility.StringEnum)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local InputPhase = require(ReplicatedStorage.Telemetry.InputActionLog.InputPhase)
local LogEntry = require(ReplicatedStorage.Telemetry.InputActionLog.LogEntry)
local BugReportRow = require(script.Parent.BugReportRow)
local BugReportInputLogRow = require(script.Parent.BugReportInputLogRow)

type BugReportRow = BugReportRow.BugReportRow
type BugReportInputLogRow = BugReportInputLogRow.BugReportInputLogRow
type LogEntry = LogEntry.LogEntry
type ReportContext = BugReportRow.ReportContext

export type ValidationResult = {
    Ok: boolean,
    Row: BugReportRow?,
    InputLogRows: {BugReportInputLogRow}?,
    Reason: string?
}

local function failure(reason: string): ValidationResult
    return table.freeze({
        Ok = false,
        Reason = reason,
    })
end

local function trim(text: string): string
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isPlausibleAge(value: any): boolean
    return typeof(value) == "number" and value >= 0 and value <= BugReportDraft.MAX_INPUT_LOG_AGE_SECONDS
end

-- The log is a bonus on a report, so entries that are wrong are dropped without rejecting the report.
-- A client keeps its newest entries; when too many arrive, the oldest are the ones cut.
local function cleanInputLog(rawLog: any): {LogEntry}
    local entries: {LogEntry} = {}
    if typeof(rawLog) ~= "table" then
        return entries
    end

    for _, rawEntry in ipairs(rawLog) do
        if typeof(rawEntry) == "table"
            and StringEnum.Contains(InputAction, rawEntry.Action)
            and InputPhase.IsValid(rawEntry.Phase)
            and isPlausibleAge(rawEntry.SecondsAgo)
        then
            table.insert(entries, LogEntry.new(rawEntry.Action, rawEntry.Phase, rawEntry.SecondsAgo))
        end
    end

    local extraEntries = #entries - BugReportDraft.MAX_INPUT_LOG_ENTRIES
    if extraEntries > 0 then
        return table.move(entries, extraEntries + 1, #entries, 1, {})
    end
    return entries
end

function BugReportValidator.Validate(draft: any, context: ReportContext): ValidationResult
    if typeof(draft) ~= "table" then
        return failure("Draft must be a table")
    end
    if typeof(draft.Description) ~= "string" then
        return failure("Description must be text")
    end

    local description = trim(draft.Description)
    if description == "" then
        return failure("Description is empty")
    end

    local isInvalidText = utf8.len(description) == nil
    if isInvalidText then
        return failure("Description is not valid text")
    end

    local isDescriptionTooLong =  utf8.len(description) :: number > BugReportDraft.MAX_DESCRIPTION_LENGTH
    if isDescriptionTooLong then
        return failure("Description is too long")
    end

    local platform = if Platform.IsValid(draft.Platform) then draft.Platform else Platform.Unknown
    local inputDevice = if InputDevice.IsValid(draft.InputDevice) then draft.InputDevice else InputDevice.Unknown
    local cleanDraft: BugReportRow.CheckedDraft = {
        Description = description,
        Platform = platform,
        InputDevice = inputDevice,
    }

    local inputLogRows: {BugReportInputLogRow} = {}
    for seq, entry in ipairs(cleanInputLog(draft.InputLog)) do
        table.insert(inputLogRows, BugReportInputLogRow.new(entry, context.ReportId, seq))
    end

    return table.freeze({
        Ok = true,
        Row = BugReportRow.new(cleanDraft, context),
        InputLogRows = inputLogRows,
    })
end

table.freeze(BugReportValidator)
return BugReportValidator
