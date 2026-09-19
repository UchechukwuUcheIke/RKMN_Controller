local MovementConfig = {
	WallSlideGravity = 0.15,
	NormalGravity = 1,
	WalkSpeed = 16,
	DashSpeed = 30,
	MaxDashDuration = 0.4
}

table.freeze(MovementConfig)

return MovementConfig
