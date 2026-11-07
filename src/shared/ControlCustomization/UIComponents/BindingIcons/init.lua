--!strict
local BindingIcons = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)

type InputBinding = InputSchemeTypes.InputBinding

-- Asset ids by binding, for example [Enum.KeyCode.W] = "rbxassetid://123". A binding left out shows its name instead.
local IMAGE_IDS: {[InputBinding]: string} = {}

function BindingIcons.GetImageId(binding: InputBinding): string?
    return IMAGE_IDS[binding]
end

return table.freeze(BindingIcons)
