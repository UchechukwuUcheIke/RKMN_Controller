local LocalPlayer = game.Players.LocalPlayer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DebugFacade = require(RKMNControllerFolder.DebugModule.DebugFacade)
local RKMNController = require(RKMNControllerFolder.RKMNController)
local KinematicWorld = require(ReplicatedStorage.KinematicWorld)


local kinematicWorld = KinematicWorld.new()

local function mountScreenGui()
    local PlayerGui = LocalPlayer.PlayerGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = PlayerGui
end

local function onCharacterAdded(character)
    local world = game.Workspace
    local kinematicController = RKMNController.new(world, character)
    local ScreenGui = LocalPlayer.PlayerGui.ScreenGui
    local _DebugTool = DebugFacade.new(world, ScreenGui, kinematicWorld, kinematicController)
    kinematicWorld:Start()
end

local function onPlayerAdded(player)
    mountScreenGui()
    player.CharacterAdded:Connect(onCharacterAdded)
    

    -- If the character already exists when the script runs, handle it manually
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)