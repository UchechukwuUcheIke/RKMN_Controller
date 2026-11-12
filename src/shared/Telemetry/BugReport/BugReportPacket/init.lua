--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packet = require(ReplicatedStorage.Packet)
local BugReportSubmitStatus = require(ReplicatedStorage.Telemetry.BugReport.BugReportSubmitStatus)

local BugReportPacket = Packet("SubmitBugReport", {
    Description = Packet.StringLong,
    Platform = Packet.String,
    InputDevice = Packet.String,
    InputLog = { {
        Action = Packet.String,
        Phase = Packet.String,
        SecondsAgo = Packet.NumberF32,
    } },
}):Response(Packet.String)

BugReportPacket.ResponseTimeoutValue = BugReportSubmitStatus.Failed

return BugReportPacket
