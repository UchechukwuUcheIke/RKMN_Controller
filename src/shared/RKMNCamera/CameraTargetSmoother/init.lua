--!strict
-- Eases the camera toward the target CFrame the solver produces each frame.
-- Position uses a critically damped SmoothDamp; rotation uses an exponential lerp.
local CameraTargetSmoother = {}
CameraTargetSmoother.__index = CameraTargetSmoother

local DEFAULT_POSITION_SMOOTH_TIME = 0.25
local DEFAULT_ROTATION_TIME_CONSTANT = 0.1

-- Cheap polynomial approximation of e^(-scaledStep), used for the damping decay.
local DECAY_QUADRATIC_COEFFICIENT = 0.48
local DECAY_CUBIC_COEFFICIENT = 0.235

type CameraTargetSmootherData = {
	_position: Vector3,
	_velocity: Vector3,
	_targetPosition: Vector3,
	_rotation: CFrame,
	_targetRotation: CFrame,
	_positionSmoothTime: number,
	_rotationTimeConstant: number,
	_hasStarted: boolean,
}

type CameraTargetSmootherPrototype = typeof(CameraTargetSmoother)

export type CameraTargetSmoother = typeof(setmetatable(
	{} :: CameraTargetSmootherData,
	{} :: CameraTargetSmootherPrototype
))

local function getRotationOnly(cframe: CFrame): CFrame
	return cframe - cframe.Position
end

function CameraTargetSmoother.new(positionSmoothTime: number?, rotationTimeConstant: number?): CameraTargetSmoother
	local self = {
		_position = Vector3.zero,
		_velocity = Vector3.zero,
		_targetPosition = Vector3.zero,
		_rotation = CFrame.identity,
		_targetRotation = CFrame.identity,
		_positionSmoothTime = positionSmoothTime or DEFAULT_POSITION_SMOOTH_TIME,
		_rotationTimeConstant = rotationTimeConstant or DEFAULT_ROTATION_TIME_CONSTANT,
		_hasStarted = false,
	} :: CameraTargetSmootherData

	return setmetatable(self, CameraTargetSmoother)
end

-- Jumps straight to the CFrame with no easing. Use for hard cuts such as respawns or teleports.
function CameraTargetSmoother.SnapTo(self: CameraTargetSmoother, cframe: CFrame): ()
	self._hasStarted = true
	self._position = cframe.Position
	self._targetPosition = cframe.Position
	self._velocity = Vector3.zero
	self._rotation = getRotationOnly(cframe)
	self._targetRotation = self._rotation
end

-- The first target snaps, so the camera never flies in from the origin.
function CameraTargetSmoother.SetTarget(self: CameraTargetSmoother, cframe: CFrame): ()
	if not self._hasStarted then
		self:SnapTo(cframe)
		return
	end

	self._targetPosition = cframe.Position
	self._targetRotation = getRotationOnly(cframe)
end

function CameraTargetSmoother._stepPosition(self: CameraTargetSmoother, dt: number): ()
	local smoothingFrequency = 2 / self._positionSmoothTime
	local scaledStep = smoothingFrequency * dt
	local decay = 1
		/ (
			1
			+ scaledStep
			+ DECAY_QUADRATIC_COEFFICIENT * scaledStep * scaledStep
			+ DECAY_CUBIC_COEFFICIENT * scaledStep * scaledStep * scaledStep
		)

	local displacementFromTarget = self._position - self._targetPosition
	local correction = (self._velocity + displacementFromTarget * smoothingFrequency) * dt

	self._velocity = (self._velocity - correction * smoothingFrequency) * decay
	self._position = self._targetPosition + (displacementFromTarget + correction) * decay
end

function CameraTargetSmoother._stepRotation(self: CameraTargetSmoother, dt: number): ()
	local alpha = 1 - math.exp(-dt / self._rotationTimeConstant)
	self._rotation = self._rotation:Lerp(self._targetRotation, alpha)
end

function CameraTargetSmoother.Update(self: CameraTargetSmoother, dt: number): CFrame
	self:_stepPosition(dt)
	self:_stepRotation(dt)

	return CFrame.new(self._position) * self._rotation
end

function CameraTargetSmoother.Destroy(self: CameraTargetSmoother): ()
	setmetatable(self :: any, nil)
end

return CameraTargetSmoother
