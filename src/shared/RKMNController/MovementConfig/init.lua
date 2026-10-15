local MovementConfig = {
	WallSlideSpeed = 4,
	WalkSpeed = 16,
	MoveSpeed = 10,
	DashSpeed = 30,
	MaxDashDuration = 0.4,
	JumpHeight = 12,
	TimeToApex = 0.3,
	FallGravityMultiplier = 1,
	JumpCutGravityMultiplier = 3,
	FallSpeed = 30,
}

table.freeze(MovementConfig)

return MovementConfig
