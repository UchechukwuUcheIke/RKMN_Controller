--!strict
local ControlPreferenceRow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local ControlPreferenceReportContext = require(script.Parent.ControlPreferenceReportContext)

type InputDevice = InputDevice.InputDevice
type ControlPreferenceReportContext = ControlPreferenceReportContext.ControlPreferenceReportContext

export type ControlPreferenceRow = {
    id: string,
    session_id: string,
    device: InputDevice,
    place_version: number
}


function ControlPreferenceRow.new(device: InputDevice, context: ControlPreferenceReportContext): ControlPreferenceRow
    return table.freeze({
        id = context.ReportId,
        session_id = context.SessionId,
        device = device,
        place_version = context.PlaceVersion,
    })
end

table.freeze(ControlPreferenceRow)
return ControlPreferenceRow
