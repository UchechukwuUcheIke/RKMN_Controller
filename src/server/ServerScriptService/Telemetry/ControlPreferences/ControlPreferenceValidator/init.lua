--!strict
local ControlPreferenceValidator = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local StringEnum = require(ReplicatedStorage.Utility.StringEnum)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local ControlPreferenceReport = require(ReplicatedStorage.Telemetry.ControlPreferences.ControlPreferenceReport)
local ControlPreferenceReportContext = require(script.Parent.ControlPreferenceReportContext)
local ControlPreferenceRow = require(script.Parent.ControlPreferenceRow)
local ControlPreferenceBindingRow = require(script.Parent.ControlPreferenceBindingRow)
local ControlPreferenceTouchRow = require(script.Parent.ControlPreferenceTouchRow)

type ControlPreferenceRow = ControlPreferenceRow.ControlPreferenceRow
type ControlPreferenceBindingRow = ControlPreferenceBindingRow.ControlPreferenceBindingRow
type ControlPreferenceTouchRow = ControlPreferenceTouchRow.ControlPreferenceTouchRow
type BindingEntry = ControlPreferenceReport.BindingEntry
type TouchControlEntry = ControlPreferenceReport.TouchControlEntry
type ControlPreferenceReportContext = ControlPreferenceReportContext.ControlPreferenceReportContext

export type ValidationResult = {
    Ok: boolean,
    Row: ControlPreferenceRow?,
    BindingRows: {ControlPreferenceBindingRow}?,
    TouchRows: {ControlPreferenceTouchRow}?,
    Reason: string?
}

type NumberRange = { Min: number, Max: number }

ControlPreferenceValidator.MAX_BINDING_ENTRIES = 100
ControlPreferenceValidator.MAX_TOUCH_CONTROLS = 20
ControlPreferenceValidator.MAX_NAME_LENGTH = 50

local POSITION_SCALE_RANGE: NumberRange = { Min = -1, Max = 2 }
local BASE_SIZE_RANGE: NumberRange = { Min = 0, Max = 5000 }
local SCALE_RANGE: NumberRange = { Min = 0, Max = 10 }
local TRANSPARENCY_RANGE: NumberRange = { Min = 0, Max = 1 }

local function failure(reason: string): ValidationResult
    return table.freeze({
        Ok = false,
        Reason = reason,
    })
end

-- NaN fails both comparisons, and infinity falls outside every range, so this also rejects both.
local function isInRange(value: any, range: NumberRange): boolean
    return typeof(value) == "number" and value >= range.Min and value <= range.Max
end

-- Binding names are the names of Roblox enum items, which are plain identifiers.
local function isBindingName(value: any): boolean
    return typeof(value) == "string"
        and #value <= ControlPreferenceValidator.MAX_NAME_LENGTH
        and string.match(value, "^[%w_]+$") ~= nil
end

local function isTouchControl(value: any): boolean
    return value == TouchGamepadLayoutRegistry.DPad or StringEnum.Contains(InputAction, value)
end

-- Entries that are wrong are dropped without rejecting the report. Repeats are dropped too, since
-- the tables allow each action and binding, or each control, only once per report.
local function cleanBindings(rawBindings: any): {BindingEntry}
    local entries: {BindingEntry} = {}
    if typeof(rawBindings) ~= "table" then
        return entries
    end

    local seen: {[string]: boolean} = {}
    for _, rawEntry in ipairs(rawBindings) do
        if #entries >= ControlPreferenceValidator.MAX_BINDING_ENTRIES then
            break
        end
        if typeof(rawEntry) ~= "table"
            or not StringEnum.Contains(InputAction, rawEntry.Action)
            or not isBindingName(rawEntry.Binding)
        then
            continue
        end

        local key = string.lower(rawEntry.Action) .. "/" .. string.lower(rawEntry.Binding)
        if not seen[key] then
            seen[key] = true
            table.insert(entries, table.freeze({ Action = rawEntry.Action, Binding = rawEntry.Binding }))
        end
    end
    return entries
end

local function cleanTouchControls(rawControls: any): {TouchControlEntry}
    local entries: {TouchControlEntry} = {}
    if typeof(rawControls) ~= "table" then
        return entries
    end

    local seen: {[string]: boolean} = {}
    for _, rawEntry in ipairs(rawControls) do
        if #entries >= ControlPreferenceValidator.MAX_TOUCH_CONTROLS then
            break
        end
        if typeof(rawEntry) ~= "table"
            or not isTouchControl(rawEntry.Control)
            or not isInRange(rawEntry.PositionScaleX, POSITION_SCALE_RANGE)
            or not isInRange(rawEntry.PositionScaleY, POSITION_SCALE_RANGE)
            or not isInRange(rawEntry.BaseSizeX, BASE_SIZE_RANGE)
            or not isInRange(rawEntry.BaseSizeY, BASE_SIZE_RANGE)
            or not isInRange(rawEntry.Scale, SCALE_RANGE)
            or not isInRange(rawEntry.Transparency, TRANSPARENCY_RANGE)
        then
            continue
        end

        local key = string.lower(rawEntry.Control)
        if not seen[key] then
            seen[key] = true
            table.insert(entries, table.freeze({
                Control = rawEntry.Control,
                PositionScaleX = rawEntry.PositionScaleX,
                PositionScaleY = rawEntry.PositionScaleY,
                BaseSizeX = rawEntry.BaseSizeX,
                BaseSizeY = rawEntry.BaseSizeY,
                Scale = rawEntry.Scale,
                Transparency = rawEntry.Transparency,
            }))
        end
    end
    return entries
end

-- A touch report carries only touch controls and every other device carries only bindings, so
-- entries of the other kind are ignored. A report with nothing left in it says nothing and is rejected.
function ControlPreferenceValidator.Validate(report: unknown, context: ControlPreferenceReportContext): ValidationResult
    if typeof(report) ~= "table" then
        return failure("Report must be a table")
    end

    local fields = report :: {[string]: any}
    local device = fields.Device
    if not InputDevice.IsValid(device) or device == InputDevice.Unknown then
        return failure("Device is not a known input device")
    end

    local bindingRows: {ControlPreferenceBindingRow} = {}
    local touchRows: {ControlPreferenceTouchRow} = {}
    if device == InputDevice.Touch then
        for _, entry in ipairs(cleanTouchControls(fields.TouchControls)) do
            table.insert(touchRows, ControlPreferenceTouchRow.new(entry, context.ReportId))
        end
    else
        for _, entry in ipairs(cleanBindings(fields.Bindings)) do
            table.insert(bindingRows, ControlPreferenceBindingRow.new(entry, context.ReportId))
        end
    end

    if #bindingRows == 0 and #touchRows == 0 then
        return failure("Report has no valid entries")
    end

    return table.freeze({
        Ok = true,
        Row = ControlPreferenceRow.new(device, context),
        BindingRows = bindingRows,
        TouchRows = touchRows,
    })
end

table.freeze(ControlPreferenceValidator)
return ControlPreferenceValidator
