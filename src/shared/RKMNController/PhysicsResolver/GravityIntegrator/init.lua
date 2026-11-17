--!strict
local GravityIntegrator = {}
GravityIntegrator.__index = GravityIntegrator
GravityIntegrator.ClassName = "GravityIntegrator"

local PhysicsResolverFolder = script.Parent
local RKMNControllerFolder = PhysicsResolverFolder.Parent
local MovementStats = require(RKMNControllerFolder.MovementStats)
local MotionState = require(PhysicsResolverFolder.MotionState)

type MovementStats = MovementStats.MovementStats
type MotionState = MotionState.MotionState

type GravityIntegratorData = {
	_movementStats: MovementStats,
	_isRiseCut: boolean,
	_fallSpeedOverride: number?,
}

type GravityIntegratorPrototype = typeof({__index = GravityIntegrator})

export type GravityIntegrator = typeof(setmetatable(
	{} :: GravityIntegratorData,
	{} :: GravityIntegratorPrototype))

function GravityIntegrator.new(movementStats: MovementStats): GravityIntegrator
	local data: GravityIntegratorData = {
		_movementStats = movementStats,
		_isRiseCut = false,
		_fallSpeedOverride = nil,
	}

	return setmetatable(data, GravityIntegrator)
end

function GravityIntegrator.CutRise(self: GravityIntegrator): ()
	self._isRiseCut = true
end

function GravityIntegrator.ClearRiseCut(self: GravityIntegrator): ()
	self._isRiseCut = false
end

function GravityIntegrator.SetFallSpeedOverride(self: GravityIntegrator, speed: number?): ()
	self._fallSpeedOverride = speed
end

function GravityIntegrator._getGravity(self: GravityIntegrator, yVelocity: number): number
	local stats = self._movementStats
	if yVelocity <= 0 then
		return stats.FallGravity
	end

	return if self._isRiseCut then stats.CutGravity else stats.RiseGravity
end

function GravityIntegrator.Apply(self: GravityIntegrator, motion: MotionState, dt: number, isGrounded: boolean): ()
	local yVelocity = motion.Velocity.Y
	if yVelocity <= 0 and isGrounded then
		motion:ZeroVelocityY()
		return
	end

	local fallSpeedCap: number = self._fallSpeedOverride or self._movementStats.FallSpeed
	motion:SetVelocityY(math.max(yVelocity - self:_getGravity(yVelocity) * dt, -fallSpeedCap))
end

table.freeze(GravityIntegrator)

return GravityIntegrator
