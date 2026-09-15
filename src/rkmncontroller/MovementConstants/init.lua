--!strict

local MovementConstants = {}
MovementConstants.__index = MovementConstants

type MovementConstantsData = {
	HitboxSize: Vector3,
	GroundCheckDistance: number,
	WallCheckDistance: number,
	MaxSlopeAngle: number,
	SkinWidth: number,
}

export type MovementConstants = typeof(setmetatable({} :: MovementConstantsData, MovementConstants))

function MovementConstants.new(characterModel: Model): MovementConstants
    local self = setmetatable({}, MovementConstants)

    self.HitboxSize = Vector3.new(10, 10, 10)
    self.GroundCheckDistance = 2
    self.WallCheckDistance = 2
    self.MaxSlopeAngle = 90
    self.SkinWidth = 90

    return self
end

return MovementConstants