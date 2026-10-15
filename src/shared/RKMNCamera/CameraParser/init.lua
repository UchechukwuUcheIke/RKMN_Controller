--!strict
local CameraZoneParser = {}

-- Pulling in the type definition we established earlier
export type CameraZone = {
	Id: string,
	Type: "Rail" | "Locked",
	Center: Vector3,
	Size: Vector3,
	FocusCFrame: CFrame?,
	CameraOffset: Vector3?,
	ClampMin: Vector3?,
	ClampMax: Vector3?
}

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
            zoneData = CameraZone.createRail(id, center, size, cameraOffset)
        end

        parsedZones[id] = zoneData
		
		-- Optional: Destroy the physical part now that we have the data
		-- to prevent it from cluttering the workspace or physics engine
		zonePart:Destroy() 
	end
	
	return parsedZones
end

return CameraZoneParser

