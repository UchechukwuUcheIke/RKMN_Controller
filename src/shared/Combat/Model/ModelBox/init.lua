--!strict
local ModelBox = {}
ModelBox.__index = ModelBox

type ModelBoxData = {
	-- The model's width and height on the combat plane, measured once when the box is built.
	Size: Vector2,

	_primaryPart: BasePart,
	-- Where the model's bounding box sits relative to its primary part.
	_offset: CFrame,
}

type ModelBoxPrototype = typeof(ModelBox)

export type ModelBox = typeof(setmetatable(
	{} :: ModelBoxData,
	{} :: ModelBoxPrototype
))

-- Measures the model's bounding box once and remembers where it sits relative to the primary part,
-- so the live bounding box, which changes with animation pose, is never read again. Combat is 2D:
-- only the X and Y of the box count, and the model is expected to face the camera when this is built.
function ModelBox.new(model: Model): ModelBox
	local primaryPart = model.PrimaryPart
	assert(primaryPart, "ModelBox requires the model to have a PrimaryPart")

	local boundingCFrame: CFrame, boundingSize: Vector3 = model:GetBoundingBox()

	local data: ModelBoxData = {
		Size = Vector2.new(boundingSize.X, boundingSize.Y),

		_primaryPart = primaryPart,
		_offset = primaryPart.CFrame:ToObjectSpace(boundingCFrame),
	}

	return setmetatable(data, ModelBox)
end

-- Where the model's box is right now.
function ModelBox.GetCenter(self: ModelBox): Vector2
	local position = (self._primaryPart.CFrame * self._offset).Position

	return Vector2.new(position.X, position.Y)
end

return ModelBox
