--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local Direction = require(ReplicatedStorage.Data.Direction)
local DamageTemplate = require(DataFolder.DamageTemplate)
local Hitbox = require(CombatFolder.Hitbox.Hitbox)
local ModelBox = require(CombatFolder.Model.ModelBox)
local Team = require(DataFolder.Team)

type Direction = Direction.Direction
type DamageTemplate = DamageTemplate.DamageTemplate
type Hitbox = Hitbox.Hitbox
type ModelBox = ModelBox.ModelBox
type Team = Team.Team

-- A hitbox that is the size of a model and stays on it, such as an enemy that hurts on contact.
-- It does not register the hitbox: the caller registers `Hitbox` and calls `Update` each frame.
local ModelHitbox = {}
ModelHitbox.__index = ModelHitbox

-- A HitboxConfig without Center and Size, which come from the model.
export type ModelHitboxConfig = {
	OwnerId: number,
	Team: Team,
	Damage: DamageTemplate,
	Direction: Direction,
	OnHit: Hitbox.OnHitCallback?,
	Enabled: boolean?,
}

type ModelHitboxData = {
	Hitbox: Hitbox,

	_box: ModelBox,
}

type ModelHitboxPrototype = typeof(ModelHitbox)

export type ModelHitbox = typeof(setmetatable(
	{} :: ModelHitboxData,
	{} :: ModelHitboxPrototype
))

function ModelHitbox.new(model: Model, config: ModelHitboxConfig): ModelHitbox
	local box = ModelBox.new(model)

	local data: ModelHitboxData = {
		Hitbox = Hitbox.new({
			OwnerId = config.OwnerId,
			Team = config.Team,
			Center = box:GetCenter(),
			Size = box.Size,
			Damage = config.Damage,
			Direction = config.Direction,
			OnHit = config.OnHit,
			Enabled = config.Enabled,
		}),

		_box = box,
	}

	return setmetatable(data, ModelHitbox)
end

-- Moves the hitbox to where the model is now. Call it every frame, after the model has moved.
function ModelHitbox.Update(self: ModelHitbox): ()
	self.Hitbox:MoveTo(self._box:GetCenter())
end

return ModelHitbox
