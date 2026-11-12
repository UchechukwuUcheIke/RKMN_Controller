--!strict
local BugReportRow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BugReportDraft = require(ReplicatedStorage.BugReportDraft)

type Platform = BugReportDraft.Platform
type InputDevice = BugReportDraft.InputDevice

-- What the server knows about the reporting player; none of it comes from the client.
export type ReportContext = {
    UserId: number,
    Username: string,
    PlaceVersion: number,
    SessionId: string,
    Position: Vector3?
}

export type BugReportRow = {
    user_id: number,
    username: string,
    description: string,
    platform: Platform,
    input_device: InputDevice,
    place_version: number,
    session_id: string,
    pos_x: number?,
    pos_y: number?,
    pos_z: number?
}

-- Builds a row from a draft that has already been checked; the draft's types are trusted here.
-- The field names match the table's columns, so the column mapping lives only in this function.
function BugReportRow.new(draft: BugReportDraft.BugReportDraft, context: ReportContext): BugReportRow
    local position = context.Position

    return table.freeze({
        user_id = context.UserId,
        username = context.Username,
        description = draft.Description,
        platform = draft.Platform,
        input_device = draft.InputDevice,
        place_version = context.PlaceVersion,
        session_id = context.SessionId,
        pos_x = if position then position.X else nil,
        pos_y = if position then position.Y else nil,
        pos_z = if position then position.Z else nil,
    })
end

table.freeze(BugReportRow)
return BugReportRow
