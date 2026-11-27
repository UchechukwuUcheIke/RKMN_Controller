--!strict
local Health = {}
Health.__index = Health

type HealthData = {
	Max: number,
	Current: number,
}

type HealthPrototype = typeof(Health)

export type Health = typeof(setmetatable(
	{} :: HealthData,
	{} :: HealthPrototype
))

function Health.new(max: number): Health
	assert(max > 0, "Health Max must be positive")

	local data: HealthData = {
		Max = max,
		Current = max,
	}

	return setmetatable(data, Health)
end

function Health.TakeDamage(self: Health, amount: number): ()
	assert(amount >= 0, "Health damage amount must not be negative")
	self.Current = math.max(0, self.Current - amount)
end

function Health.IsDepleted(self: Health): boolean
	return self.Current == 0
end

return Health
