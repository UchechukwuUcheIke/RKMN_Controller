--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JSONUtils = require(ReplicatedStorage.JSONUtils)

type NumberArray = JSONUtils.NumberArray

local CameraZoneRecord = {}

CameraZoneRecord.SCHEMA_VERSION = 1

export type CameraZoneRecord = {
	Id: string,
	Type: string,
	Center: NumberArray,
	Size: NumberArray,

	-- Rail zones
	CameraOffset: NumberArray?,
	VerticalFollow: string?,
	DeadzoneFraction: number?,
	GroundedScrollSpeed: number?,

	-- Locked zones
	FocusCFrame: NumberArray?,
}

export type CameraZoneRecordDocument = {
	Version: number,
	CameraZones: { CameraZoneRecord },
}

return CameraZoneRecord
