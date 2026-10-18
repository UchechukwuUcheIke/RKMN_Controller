--!strict
export type Weapon = {
	Update: (self: any, dt: number) -> (),
	PressTrigger: (self: any) -> (),
	ReleaseTrigger: (self: any) -> (),
	SetEnabled: (self: any, enabled: boolean) -> (),
}

return nil
