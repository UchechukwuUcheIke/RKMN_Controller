--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local CameraZone = require(RKMNCameraFolder.Data.CameraZone)
local CameraZoneType = require(RKMNCameraFolder.Data.CameraZoneType)

local CameraTargetSolver = {}

local FALLBACK_CAMERA_OFFSET = Vector3.new(0, 4, 30)

type CameraZone = CameraZone.CameraZone
type RailCameraZone = CameraZone.RailCameraZone
type LockedCameraZone = CameraZone.LockedCameraZone

local function clampToZone(position: Vector3, zone: RailCameraZone): Vector3
	local constraints = zone.RailConstraints
	return Vector3.new(
		math.clamp(position.X, constraints.ClampMin.X, constraints.ClampMax.X),
		math.clamp(position.Y, constraints.ClampMin.Y, constraints.ClampMax.Y),
		position.Z
	)
end

local function solveFallback(playerCFrame: CFrame): CFrame
	return CFrame.new(playerCFrame.Position + FALLBACK_CAMERA_OFFSET)
end

local function solveRail(playerCFrame: CFrame, zone: RailCameraZone): CFrame
	local desiredPosition = playerCFrame.Position + zone.RailConstraints.CameraOffset
	return CFrame.new(clampToZone(desiredPosition, zone))
end

local function solveLocked(_playerCFrame: CFrame, zone: LockedCameraZone): CFrame
	return zone.FixedViewport.CFrame
end

function CameraTargetSolver.Solve(playerCFrame: CFrame, zone: CameraZone?): CFrame
	if not zone then
		return solveFallback(playerCFrame)
	end

	if zone.Type == CameraZoneType.Locked then
		return solveLocked(playerCFrame, zone :: LockedCameraZone)
	end

	return solveRail(playerCFrame, zone :: RailCameraZone)
end

return CameraTargetSolver
