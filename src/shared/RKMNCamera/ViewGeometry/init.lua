--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local DataFolder = RKMNCameraFolder.Data
local CameraZone = require(DataFolder.CameraZone)

type SpatialBounds = CameraZone.SpatialBounds

local ViewGeometry = {}

export type ViewParams = {
	VerticalFieldOfView: number,
	Aspect: number,
}

const MAX_ASPECT = 16 / 9

function ViewGeometry.getVisibleHalfSize(view: ViewParams, distanceToPlayerPlane: number): Vector2
	local halfHeight = distanceToPlayerPlane * math.tan(math.rad(view.VerticalFieldOfView) / 2)
	local halfWidth = halfHeight * math.min(view.Aspect, MAX_ASPECT)
	return Vector2.new(halfWidth, halfHeight)
end

local function clampAxisToRoom(
	desiredCenter: number,
	roomMin: number,
	roomMax: number,
	visibleHalfSpan: number
): number
	local lowestCenter = roomMin + visibleHalfSpan
	local highestCenter = roomMax - visibleHalfSpan

	local roomIsSmallerThanScreen = lowestCenter > highestCenter
	if roomIsSmallerThanScreen then
		return (roomMin + roomMax) / 2
	end

	return math.clamp(desiredCenter, lowestCenter, highestCenter)
end

function ViewGeometry.clampToRoom(desiredCenter: Vector2, bounds: SpatialBounds, visibleHalfSize: Vector2): Vector2
	local roomHalfSize = bounds.Size / 2
	local roomCenter = bounds.Center

	return Vector2.new(
		clampAxisToRoom(desiredCenter.X, roomCenter.X - roomHalfSize.X, roomCenter.X + roomHalfSize.X, visibleHalfSize.X),
		clampAxisToRoom(desiredCenter.Y, roomCenter.Y - roomHalfSize.Y, roomCenter.Y + roomHalfSize.Y, visibleHalfSize.Y)
	)
end

return ViewGeometry