--!strict
local BugReportDraft = {}

local Platform = require(script.Platform)
local InputDevice = require(script.InputDevice)

export type Platform = Platform.Platform
export type InputDevice = InputDevice.InputDevice

export type BugReportDraft = {
    Description: string,
    Platform: Platform,
    InputDevice: InputDevice
}

BugReportDraft.MAX_DESCRIPTION_LENGTH = 2000

table.freeze(BugReportDraft)
return BugReportDraft
