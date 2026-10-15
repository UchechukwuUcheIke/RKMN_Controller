--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local DataFolder = RKMNCameraFolder.Data
local CameraZone = require(DataFolder.CameraZone)
local ViewGeometry = require(RKMNCameraFolder.ViewGeometry)
local VerticalFocus = require(RKMNCameraFolder.VerticalFocus)
local CameraZoneType = require(DataFolder.CameraZoneType)

local CameraTargetSolver = {}

local FALLBACK_CAMERA_OFFSET = Vector3.new(0, 4, 30)

type CameraZone = CameraZone.CameraZone
type RailCameraZone = CameraZone.RailCameraZone
type LockedCameraZone = CameraZone.LockedCameraZone

export type ViewParams = ViewGeometry.ViewParams
export type CameraState = VerticalFocus.CameraState

local function solveFallback(playerCFrame: CFrame, previousState: CameraState?): (CFrame, CameraState?)
	return CFrame.new(playerCFrame.Position + FALLBACK_CAMERA_OFFSET), previousState
end

local function solveLocked(zone: LockedCameraZone, previousState: CameraState?): (CFrame, CameraState?)
	return zone.FixedViewport.CFrame, previousState
end

local function solveRail(
	playerCFrame: CFrame,
	zone: RailCameraZone,
	view: ViewParams,
	previousState: CameraState?,
	isGrounded: boolean,
	dt: number
): (CFrame, CameraState)
	local cameraOffset = zone.RailConstraints.CameraOffset
	local playerPosition = playerCFrame.Position
	local visibleHalfSize = ViewGeometry.getVisibleHalfSize(view, math.abs(cameraOffset.Z))

	local startingState: CameraState = previousState or { FocusY = playerPosition.Y }
	local focusY = VerticalFocus.compute(startingState.FocusY, playerPosition.Y, isGrounded, zone, visibleHalfSize.Y, dt)

	local desiredCenter = Vector2.new(playerPosition.X + cameraOffset.X, focusY + cameraOffset.Y)
	local clampedCenter = ViewGeometry.clampToRoom(desiredCenter, zone.SpatialBounds, visibleHalfSize)

	local nextState: CameraState = { FocusY = clampedCenter.Y - cameraOffset.Y }
	local cameraPosition = Vector3.new(clampedCenter.X, clampedCenter.Y, playerPosition.Z + cameraOffset.Z)

	return CFrame.new(cameraPosition), nextState
end

-- Pure: same inputs, same outputs. The caller owns the state and feeds it back each frame.
-- Pass previousState = nil when the active zone changes, or seed it from a transition tween.
function CameraTargetSolver.Solve(
	playerCFrame: CFrame,
	zone: CameraZone?,
	view: ViewParams,
	previousState: CameraState?,
	isGrounded: boolean,
	dt: number
): (CFrame, CameraState?)
	if not zone then
		return solveFallback(playerCFrame, previousState)
	end

	if zone.Type == CameraZoneType.Locked then
		return solveLocked(zone :: LockedCameraZone, previousState)
	end

	return solveRail(playerCFrame, zone :: RailCameraZone, view, previousState, isGrounded, dt)
end

return CameraTargetSolver