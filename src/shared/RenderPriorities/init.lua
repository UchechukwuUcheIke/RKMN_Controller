--!strict
local RenderPriorities = {
	World = Enum.RenderPriority.Character.Value,
	Camera = Enum.RenderPriority.Camera.Value + 1,
}

table.freeze(RenderPriorities)

return RenderPriorities
