local MovementConfig = {
	WallSlideGravity = 0.15,
	NormalGravity = 1,
	WalkSpeed = 16,
	DashSpeed = 30,
	MaxDashDuration = 0.4,
	MaxFallSpeed = 1,
	JumpDampeningFactor = 0.5,
}

table.freeze(MovementConfig)

return MovementConfig
