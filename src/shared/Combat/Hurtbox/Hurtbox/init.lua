--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Bounds = require(DataFolder.Bounds)
local DamagePayload = require(DataFolder.DamagePayload)
local HitResult = require(CombatFolder.Hurtbox.HitResult)
local Team = require(DataFolder.Team)

type Bounds = Bounds.Bounds
type Team = Team.Team
type HitResult = HitResult.HitResult
type DamagePayload = DamagePayload.DamagePayload

local Hurtbox = {}
Hurtbox.__index = Hurtbox

export type ReceiveCallback = (damage: DamagePayload) -> HitResult

export type HurtboxConfig = {
	OwnerId: number,
	Team: Team,
	Center: Vector2,
	Size: Vector2,
	Receive: ReceiveCallback,
	Enabled: boolean?,
}

type HurtboxData = {
	OwnerId: number,
	Team: Team,
	Enabled: boolean,
	Receive: ReceiveCallback,

	_center: Vector2,
	_size: Vector2,
	_bounds: Bounds,
}

type HurtboxPrototype = typeof(Hurtbox)

export type Hurtbox = typeof(setmetatable(
	{} :: HurtboxData,
	{} :: HurtboxPrototype
))

function Hurtbox.new(config: HurtboxConfig): Hurtbox
	assert(config.Size.X > 0 and config.Size.Y > 0, "Hurtbox Size must be positive on both axes")

	local data: HurtboxData = {
		OwnerId = config.OwnerId,
		Team = config.Team,
		Enabled = if config.Enabled == nil then true else config.Enabled,
		Receive = config.Receive,

		_center = config.Center,
		_size = config.Size,
		_bounds = Bounds.new(config.Center, config.Size),
	}

	return setmetatable(data, Hurtbox)
end

function Hurtbox.GetBounds(self: Hurtbox): Bounds
	return self._bounds
end

function Hurtbox.MoveTo(self: Hurtbox, center: Vector2): ()
	self._center = center
	self._bounds = Bounds.new(center, self._size)
end

function Hurtbox.Resize(self: Hurtbox, size: Vector2): ()
	assert(size.X > 0 and size.Y > 0, "Hurtbox Size must be positive on both axes")
	self._size = size
	self._bounds = Bounds.new(self._center, size)
end

return Hurtbox
