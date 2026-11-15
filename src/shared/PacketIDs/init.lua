--!strict
export type PacketID = string

local PacketIDs = {
    SubmitBugReport = "SubmitBugReport" :: PacketID,
    ReportControlPreference = "ReportControlPreference" :: PacketID,
}

table.freeze(PacketIDs)
return PacketIDs
