--!strict
export type BugReportSubmitStatus = "Sent" | "Cooldown" | "Invalid" | "Failed"

local BugReportSubmitStatus = {
    Sent = "Sent" :: BugReportSubmitStatus,
    Cooldown = "Cooldown" :: BugReportSubmitStatus,
    Invalid = "Invalid" :: BugReportSubmitStatus,
    Failed = "Failed" :: BugReportSubmitStatus,
}

table.freeze(BugReportSubmitStatus)
return BugReportSubmitStatus
