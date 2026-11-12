--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packet = require(ReplicatedStorage.Packet)
local BugReportSubmitStatus = require(ReplicatedStorage.BugReport.BugReportSubmitStatus)

local BugReportPacket = Packet("SubmitBugReport", {
    Description = Packet.StringLong,
    Platform = Packet.String,
    InputDevice = Packet.String,
}):Response(Packet.String)

BugReportPacket.ResponseTimeoutValue = BugReportSubmitStatus.Failed

return BugReportPacket
