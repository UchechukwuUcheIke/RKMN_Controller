--!strict
local HitResult = {
	Applied = "Applied",
	Blocked = "Blocked",
	Ignored = "Ignored",
	Killed = "Killed",
}

export type HitResult = "Applied" | "Blocked" | "Ignored" | "Killed"

table.freeze(HitResult)

return HitResult
