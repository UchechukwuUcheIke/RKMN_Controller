--!strict
local RenderPriorities = {
	Kinematic = Enum.RenderPriority.Character.Value,
	Combat = Enum.RenderPriority.Character.Value + 1,
	Camera = Enum.RenderPriority.Camera.Value + 1,
}

table.freeze(RenderPriorities)

return RenderPriorities
