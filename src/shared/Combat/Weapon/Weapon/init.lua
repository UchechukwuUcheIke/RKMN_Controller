--!strict
-- What the combat module needs from any weapon: a per-frame update, called with the same dt the
-- projectile simulation steps with. Firing is each weapon's own business.
export type Weapon = {
	Update: (self: any, dt: number) -> (),
}

return nil
