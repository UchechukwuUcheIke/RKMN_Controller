--!strict
local LedgeGuard = {}
LedgeGuard.__index = LedgeGuard
LedgeGuard.ClassName = "LedgeGuard"

local RKMNControllerFolder = script.Parent.Parent
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local SurfaceHits = require(RKMNControllerFolder.SurfaceHits)
local GroundProbe = require(script.Parent.GroundProbe)

type SweepResolution = SweepResolution.SweepResolution
type GroundProbe = GroundProbe.GroundProbe

const LEDGE_BISECT_STEPS = 5
const MIN_LEDGE_CHECK_DISTANCE = 1e-4

type LedgeGuardData = {
	_isEnabled: boolean,
	_groundProbe: GroundProbe,
}

type LedgeGuardPrototype = typeof({__index = LedgeGuard})

export type LedgeGuard = typeof(setmetatable(
	{} :: LedgeGuardData,
	{} :: LedgeGuardPrototype))

function LedgeGuard.new(groundProbe: GroundProbe): LedgeGuard
	local data: LedgeGuardData = {
		_isEnabled = false,
		_groundProbe = groundProbe,
	}

	return setmetatable(data, LedgeGuard)
end

function LedgeGuard.SetEnabled(self: LedgeGuard, enabled: boolean): ()
	self._isEnabled = enabled
end

function LedgeGuard._isActive(self: LedgeGuard): boolean
	return self._isEnabled and self._groundProbe:IsGrounded()
end

function LedgeGuard._findSupportedFraction(self: LedgeGuard, horizontal: Vector3): number
	local supportedFraction = 0
	local unsupportedFraction = 1

	for _ = 1, LEDGE_BISECT_STEPS do
		local midFraction = (supportedFraction + unsupportedFraction) / 2
		if self._groundProbe:HasWalkableGroundAt(horizontal * midFraction) then
			supportedFraction = midFraction
		else
			unsupportedFraction = midFraction
		end
	end

	return supportedFraction
end

local function withLedgeHit(resolution: SweepResolution, clampedDelta: Vector3): SweepResolution
	local hits = resolution.SurfaceHits
	return SweepResolution.new(
		resolution.CastRecord,
		clampedDelta,
		SurfaceHits.new(hits.HitFloor, hits.HitWall, hits.HitCeiling, true)
	)
end

function LedgeGuard.Apply(self: LedgeGuard, resolution: SweepResolution): SweepResolution
	if not self:_isActive() then
		return resolution
	end

	local safeDelta = resolution.SafeDelta
	local horizontal = Vector3.new(safeDelta.X, 0, safeDelta.Z)
	if horizontal.Magnitude < MIN_LEDGE_CHECK_DISTANCE or self._groundProbe:HasWalkableGroundAt(horizontal) then
		return resolution
	end

	local fraction = self:_findSupportedFraction(horizontal)
	local clampedDelta = Vector3.new(safeDelta.X * fraction, safeDelta.Y, safeDelta.Z * fraction)
	return withLedgeHit(resolution, clampedDelta)
end

table.freeze(LedgeGuard)

return LedgeGuard
