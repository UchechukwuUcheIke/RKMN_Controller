local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerSetup = require(ReplicatedStorage.RKMNControllerSetup)
local RKMNCameraSetup = require(ReplicatedStorage.RKMNCameraSetup)

local rkmnCamera = RKMNCameraSetup.Setup(workspace.CurrentCamera)

local function onCharacterAdded(character: Model)
    wait(1)
    RKMNControllerSetup.Setup(character)
    rkmnCamera:SetPlayerTarget(character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
