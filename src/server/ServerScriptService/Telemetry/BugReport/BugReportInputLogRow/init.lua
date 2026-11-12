--!strict
local BugReportInputLogRow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputPhase = require(ReplicatedStorage.Telemetry.InputActionLog.InputPhase)
local LogEntry = require(ReplicatedStorage.Telemetry.InputActionLog.LogEntry)

type LogEntry = LogEntry.LogEntry

-- Shaped like a row of input_log_entries. The id column is filled in by the database.
export type BugReportInputLogRow = {
    report_id: string,
    seq: number,
    action: string,
    phase: InputPhase.InputPhase,
    seconds_before_report: number
}

-- seq keeps the entries in the order they happened. Actions are stored lowercase, like every other
-- stored value.
function BugReportInputLogRow.new(entry: LogEntry, reportId: string, seq: number): BugReportInputLogRow
    return table.freeze({
        report_id = reportId,
        seq = seq,
        action = string.lower(entry.Action),
        phase = entry.Phase,
        seconds_before_report = entry.SecondsAgo,
    })
end

table.freeze(BugReportInputLogRow)
return BugReportInputLogRow
