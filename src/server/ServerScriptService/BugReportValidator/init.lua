--!strict
local BugReportValidator = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BugReportDraft = require(ReplicatedStorage.BugReportDraft)
local Platform = require(ReplicatedStorage.BugReportDraft.Platform)
local InputDevice = require(ReplicatedStorage.BugReportDraft.InputDevice)
local BugReportRow = require(script.Parent.BugReportRow)

type BugReportRow = BugReportRow.BugReportRow
type BugReportDraft = BugReportDraft.BugReportDraft
type ReportContext = BugReportRow.ReportContext

export type ValidationResult = {
    Ok: boolean,
    Row: BugReportRow?,
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
    local cleanDraft: BugReportDraft.BugReportDraft = {
        Description = description,
        Platform = platform,
        InputDevice = inputDevice,
    }

    return table.freeze({
        Ok = true,
        Row = BugReportRow.new(cleanDraft, context),
    })
end

table.freeze(BugReportValidator)
return BugReportValidator
