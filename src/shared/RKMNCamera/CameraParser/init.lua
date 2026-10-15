--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraZone = require(ReplicatedStorage.RKMNCamera.Data.CameraZone)

type CameraZone = CameraZone.CameraZone

local CameraZoneParser = {}

-- Takes the physical folder of parts and returns pure data
function CameraZoneParser.ParseMap(zonesFolder: Folder): { [string]: CameraZone }
	local parsedZones = {}
	
	for _, zonePart in ipairs(zonesFolder:GetChildren()) do
		if not zonePart:IsA("BasePart") then continue end
		
		-- Inside CameraZoneParser:
        local id = zonePart.Name
        local zoneType = zonePart:GetAttribute("ZoneType") :: string
        local center = zonePart.Position
        local size = zonePart.Size

        local zoneData: CameraZone

        if zoneType == "Locked" then
            local focusCFrame = zonePart:FindFirstChild("FocusPoint").WorldCFrame
            zoneData = CameraZone.createLocked(id, center, size, focusCFrame)
        else
            local cameraOffset = zonePart:GetAttribute("CameraOffset") :: Vector3
            zoneData = CameraZone.createRail(id, center, size, cameraOffset, {
                VerticalFollow = zonePart:GetAttribute("VerticalFollow") :: CameraZone.VerticalFollow?,
                DeadzoneFraction = zonePart:GetAttribute("DeadzoneFraction") :: number?,
                GroundedScrollSpeed = zonePart:GetAttribute("GroundedScrollSpeed") :: number?,
            })
        end

        parsedZones[id] = zoneData
		
		-- Optional: Destroy the physical part now that we have the data
		-- to prevent it from cluttering the workspace or physics engine
		zonePart:Destroy() 
	end
	
	return parsedZones
end

return CameraZoneParser

