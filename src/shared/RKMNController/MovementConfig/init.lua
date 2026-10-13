local MovementConfig = {
	WallSlideGravity = 0.15,
	NormalGravity = 1,
	WalkSpeed = 16,
	MoveSpeed = 10,
	DashSpeed = 30,
	MaxDashDuration = 0.4,
	JumpHeight = 12,
	TimeToApex = 0.4,
	FallSpeed = 30,
	JumpCutSpeedFraction = 0.4,
	JumpCutDuration = 0.08,
}

table.freeze(MovementConfig)

return MovementConfig
