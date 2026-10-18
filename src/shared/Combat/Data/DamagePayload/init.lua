--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local DamageTemplate = require(DataFolder.DamageTemplate)
local Direction = require(ReplicatedStorage.Data.Direction)
local Team = require(DataFolder.Team)

type DamageTemplate = DamageTemplate.DamageTemplate
type Direction = Direction.Direction
type Team = Team.Team

local DamagePayload = {}

export type DamagePayload = {
	Amount: number,
	SourceOwnerId: number,
	Team: Team,
	Knockback: Vector2,
	HitstopDuration: number,
	Tags: { string },
}

function DamagePayload.new(config: DamagePayload): DamagePayload
	assert(config.Amount >= 0, "DamagePayload Amount must not be negative")
	assert(config.HitstopDuration >= 0, "DamagePayload HitstopDuration must not be negative")

	local tags = config.Tags
	tags = table.freeze(table.clone(tags))

	local payload: DamagePayload = {
		Amount = config.Amount,
		SourceOwnerId = config.SourceOwnerId,
		Team = config.Team,
		Knockback = config.Knockback,
		HitstopDuration = config.HitstopDuration,
		Tags = tags,
	}

	return table.freeze(payload)
end

-- Builds the payload for a source facing the given direction. A template's knockback is written for
-- a source facing right, so its horizontal part is mirrored when the source faces left.
function DamagePayload.fromTemplate(
	template: DamageTemplate,
	sourceOwnerId: number,
	team: Team,
	direction: Direction
): DamagePayload
	return DamagePayload.new({
		Amount = template.Amount,
		SourceOwnerId = sourceOwnerId,
		Team = team,
		Knockback = Vector2.new(template.Knockback.X * direction.X, template.Knockback.Y),
		HitstopDuration = template.HitstopDuration,
		Tags = template.Tags,
	})
end

return DamagePayload
