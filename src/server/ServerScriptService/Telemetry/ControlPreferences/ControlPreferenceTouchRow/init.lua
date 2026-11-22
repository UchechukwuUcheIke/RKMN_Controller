--!strict
local ControlPreferenceTouchRow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlPreferenceReport = require(ReplicatedStorage.Telemetry.ControlPreferences.ControlPreferenceReport)

type TouchControlEntry = ControlPreferenceReport.TouchControlEntry

export type ControlPreferenceTouchRow = {
    report_id: string,
    control: string,
    position_scale_x: number,
    position_scale_y: number,
    base_size_x: number,
    base_size_y: number,
    scale: number,
    transparency: number
}

function ControlPreferenceTouchRow.new(entry: TouchControlEntry, reportId: string): ControlPreferenceTouchRow
    return table.freeze({
        report_id = reportId,
        control = string.lower(entry.Control),
        position_scale_x = entry.PositionScaleX,
        position_scale_y = entry.PositionScaleY,
        base_size_x = entry.BaseSizeX,
        base_size_y = entry.BaseSizeY,
        scale = entry.Scale,
        transparency = entry.Transparency,
    })
end

table.freeze(ControlPreferenceTouchRow)
return ControlPreferenceTouchRow
