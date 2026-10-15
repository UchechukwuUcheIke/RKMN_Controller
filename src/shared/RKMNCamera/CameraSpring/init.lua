--!strict
local CameraSpring = {}
CameraSpring.__index = CameraSpring

local DEFAULT_POSITION_SMOOTH_TIME = 0.25
local DEFAULT_ROTATION_TIME_CONSTANT = 0.1

type CameraSpringData = {
	_position: Vector3,
	_velocity: Vector3,
	_targetPosition: Vector3,
	_rotation: CFrame,
	_targetRotation: CFrame,
	_positionSmoothTime: number,
	_rotationTimeConstant: number,
}

type CameraSpringPrototype = typeof(CameraSpring)

export type CameraSpring = typeof(setmetatable(
	{} :: CameraSpringData,
	{} :: CameraSpringPrototype
))

local function getRotationOnly(cframe: CFrame): CFrame
	return cframe - cframe.Position
end

function CameraSpring.new(positionSmoothTime: number?, rotationTimeConstant: number?): CameraSpring
	local self = {
		_position = Vector3.zero,
		_velocity = Vector3.zero,
		_targetPosition = Vector3.zero,
		_rotation = CFrame.identity,
		_targetRotation = CFrame.identity,
		_positionSmoothTime = positionSmoothTime or DEFAULT_POSITION_SMOOTH_TIME,
		_rotationTimeConstant = rotationTimeConstant or DEFAULT_ROTATION_TIME_CONSTANT,
	} :: CameraSpringData

	return setmetatable(self, CameraSpring)
end

function CameraSpring.SnapTo(self: CameraSpring, cframe: CFrame): ()
	self._position = cframe.Position
	self._targetPosition = cframe.Position
	self._velocity = Vector3.zero
	self._rotation = getRotationOnly(cframe)
	self._targetRotation = self._rotation
end

function CameraSpring.SetTarget(self: CameraSpring, cframe: CFrame): ()
	self._targetPosition = cframe.Position
	self._targetRotation = getRotationOnly(cframe)
end

function CameraSpring._stepPosition(self: CameraSpring, dt: number): ()
	local omega = 2 / self._positionSmoothTime
	local x = omega * dt
	local decay = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)

	local offset = self._position - self._targetPosition
	local temp = (self._velocity + offset * omega) * dt

	self._velocity = (self._velocity - temp * omega) * decay
	self._position = self._targetPosition + (offset + temp) * decay
end

function CameraSpring._stepRotation(self: CameraSpring, dt: number): ()
	local alpha = 1 - math.exp(-dt / self._rotationTimeConstant)
	self._rotation = self._rotation:Lerp(self._targetRotation, alpha)
end

function CameraSpring.Update(self: CameraSpring, dt: number): CFrame
	self:_stepPosition(dt)
	self:_stepRotation(dt)

	return CFrame.new(self._position) * self._rotation
end

function CameraSpring.Destroy(self: CameraSpring): ()
	setmetatable(self :: any, nil)
end

return CameraSpring
