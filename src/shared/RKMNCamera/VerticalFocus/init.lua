--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local DataFolder = RKMNCameraFolder.Data
local CameraZone = require(DataFolder.CameraZone)

type RailCameraZone = CameraZone.RailCameraZone
type RailConstraints = CameraZone.RailConstraints

local VerticalFocus = {}

export type CameraState = {
	FocusY: number,
}

local function pushFocusToKeepPlayerInsideDeadzone(focusY: number, playerY: number, deadzoneHalfHeight: number): number
	if playerY > focusY + deadzoneHalfHeight then
		return playerY - deadzoneHalfHeight
	elseif playerY < focusY - deadzoneHalfHeight then
		return playerY + deadzoneHalfHeight
	end
	return focusY
end

local function easeFocusTowardPlayer(focusY: number, playerY: number, scrollSpeed: number, dt: number): number
	local maxStep = scrollSpeed * dt
	return focusY + math.clamp(playerY - focusY, -maxStep, maxStep)
end

local function followWithDeadzone(
	previousFocusY: number,
	playerY: number,
	isGrounded: boolean,
	constraints: RailConstraints,
	visibleHalfHeight: number,
	dt: number
): number
	local deadzoneHalfHeight = constraints.DeadzoneFraction * visibleHalfHeight
	local focusY = pushFocusToKeepPlayerInsideDeadzone(previousFocusY, playerY, deadzoneHalfHeight)

	if isGrounded then
		focusY = easeFocusTowardPlayer(focusY, playerY, constraints.GroundedScrollSpeed, dt)
	end

	return focusY
end

function VerticalFocus.compute(
	previousFocusY: number,
	playerY: number,
	isGrounded: boolean,
	zone: RailCameraZone,
	visibleHalfHeight: number,
	dt: number
): number
	local constraints = zone.RailConstraints

	if constraints.VerticalFollow == "Tracking" then
		return playerY
	elseif constraints.VerticalFollow == "Locked" then
		return zone.SpatialBounds.Center.Y - constraints.CameraOffset.Y
	end

	return followWithDeadzone(previousFocusY, playerY, isGrounded, constraints, visibleHalfHeight, dt)
end

return VerticalFocus