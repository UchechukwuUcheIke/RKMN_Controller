--!strict
local DamageTemplate = {}

export type DamageTemplate = {
	Amount: number,
	Knockback: Vector2,
	HitstopDuration: number,
	Tags: { string },
}

export type DamageTemplateConfig = {
	Amount: number,
	Knockback: Vector2?,
	HitstopDuration: number?,
	Tags: { string }?,
}

function DamageTemplate.new(config: DamageTemplateConfig): DamageTemplate
	local hitstopDuration = config.HitstopDuration or 0

	assert(config.Amount >= 0, "DamageTemplate Amount must not be negative")
	assert(hitstopDuration >= 0, "DamageTemplate HitstopDuration must not be negative")

    local tags = table.freeze(table.clone(config.Tags or {}))

	local template: DamageTemplate = {
		Amount = config.Amount,
		Knockback = config.Knockback or Vector2.zero,
		HitstopDuration = hitstopDuration,
		Tags = tags,
	}

	return table.freeze(template)
end

return DamageTemplate
