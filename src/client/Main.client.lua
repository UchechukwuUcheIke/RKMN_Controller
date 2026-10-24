local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerSetup = require(ReplicatedStorage.RKMNControllerSetup)
local RKMNCameraSetup = require(ReplicatedStorage.RKMNCameraSetup)
local PlayerCombatSetup = require(ReplicatedStorage.Combat.PlayerCombatSetup)

local rkmnCamera = RKMNCameraSetup.Setup(workspace.CurrentCamera)

local playerCombat

local function onCharacterAdded(character: Model)
    wait(1)
    local controller = RKMNControllerSetup.Setup(character)
    if playerCombat then
        playerCombat:Destroy()
    end
    playerCombat = PlayerCombatSetup.Setup(controller, character)
    rkmnCamera:SetPlayerTarget(character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
