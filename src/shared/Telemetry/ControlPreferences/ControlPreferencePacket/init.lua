--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packet = require(ReplicatedStorage.Packet)
local PacketIDs = require(ReplicatedStorage.PacketIDs)

local ControlPreferencePacket = Packet(PacketIDs.ReportControlPreference, {
    Device = Packet.String,
    Bindings = { {
        Action = Packet.String,
        Binding = Packet.String,
    } },
    TouchControls = { {
        Control = Packet.String,
        PositionScaleX = Packet.NumberF32,
        PositionScaleY = Packet.NumberF32,
        BaseSizeX = Packet.NumberF32,
        BaseSizeY = Packet.NumberF32,
        Scale = Packet.NumberF32,
        Transparency = Packet.NumberF32,
    } },
})

return ControlPreferencePacket
