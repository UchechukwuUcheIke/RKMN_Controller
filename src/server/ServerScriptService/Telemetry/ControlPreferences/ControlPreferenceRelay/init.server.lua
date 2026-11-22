--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlPreferencePacket = require(ReplicatedStorage.Telemetry.ControlPreferences.ControlPreferencePacket)
local ControlPreferenceSubmitter = require(script.Parent.ControlPreferenceSubmitter)

ControlPreferencePacket.OnServerEvent:Connect(function(player: Player, report)
    ControlPreferenceSubmitter.Submit(player, report)
end)
