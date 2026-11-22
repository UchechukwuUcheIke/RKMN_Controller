--!strict
local ControlPreferenceRow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputDevice = require(ReplicatedStorage.Data.InputDevice)

type InputDevice = InputDevice.InputDevice

export type ReportContext = {
    ReportId: string,
    PlaceVersion: number,
    SessionId: string
}

export type ControlPreferenceRow = {
    id: string,
    session_id: string,
    device: InputDevice,
    place_version: number
}


function ControlPreferenceRow.new(device: InputDevice, context: ReportContext): ControlPreferenceRow
    return table.freeze({
        id = context.ReportId,
        session_id = context.SessionId,
        device = device,
        place_version = context.PlaceVersion,
    })
end

table.freeze(ControlPreferenceRow)
return ControlPreferenceRow
