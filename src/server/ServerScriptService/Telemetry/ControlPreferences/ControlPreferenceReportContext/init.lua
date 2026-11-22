--!strict
local ControlPreferenceReportContext = {}

-- What the server knows about the reporting session; none of it comes from the client.
export type ControlPreferenceReportContext = {
    ReportId: string,
    PlaceVersion: number,
    SessionId: string
}

function ControlPreferenceReportContext.new(
    reportId: string,
    placeVersion: number,
    sessionId: string
): ControlPreferenceReportContext
    return table.freeze({
        ReportId = reportId,
        PlaceVersion = placeVersion,
        SessionId = sessionId,
    })
end

table.freeze(ControlPreferenceReportContext)
return ControlPreferenceReportContext
