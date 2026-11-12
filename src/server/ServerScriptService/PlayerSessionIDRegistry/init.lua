--!strict
local PlayerSessionIDRegistry = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local sessionIdsByPlayer: {[Player]: string} = {}

function PlayerSessionIDRegistry.Get(player: Player): string
    local sessionId = sessionIdsByPlayer[player]
    if not sessionId then
        sessionId = HttpService:GenerateGUID(false)
        sessionIdsByPlayer[player] = sessionId
    end
    return sessionId
end

Players.PlayerRemoving:Connect(function(player: Player)
    sessionIdsByPlayer[player] = nil
end)

table.freeze(PlayerSessionIDRegistry)
return PlayerSessionIDRegistry
