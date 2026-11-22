--!strict
local ControlPreferenceBindingRow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlPreferenceReport = require(ReplicatedStorage.Telemetry.ControlPreferences.ControlPreferenceReport)

type BindingEntry = ControlPreferenceReport.BindingEntry

export type ControlPreferenceBindingRow = {
    report_id: string,
    action: string,
    binding: string
}

function ControlPreferenceBindingRow.new(entry: BindingEntry, reportId: string): ControlPreferenceBindingRow
    return table.freeze({
        report_id = reportId,
        action = string.lower(entry.Action),
        binding = string.lower(entry.Binding),
    })
end

table.freeze(ControlPreferenceBindingRow)
return ControlPreferenceBindingRow
