--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BugReportPacket = require(ReplicatedStorage.BugReportPacket)
local BugReportSubmitter = require(script.Parent.BugReportSubmitter)

BugReportPacket.OnServerInvoke = function(player: Player, draft)
    return BugReportSubmitter.Submit(player, draft)
end
