--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local Hurtbox = require(CombatFolder.Hurtbox.Hurtbox)
local ModelBox = require(CombatFolder.Model.ModelBox)
local Team = require(CombatFolder.Data.Team)

type Hurtbox = Hurtbox.Hurtbox
type ModelBox = ModelBox.ModelBox
type Team = Team.Team

-- A hurtbox that is the size of a model and stays on it, such as a character's body.
-- It does not register the hurtbox: the caller registers `Hurtbox` and calls `Update` each frame.
local ModelHurtbox = {}
ModelHurtbox.__index = ModelHurtbox

-- A HurtboxConfig without Center and Size, which come from the model.
export type ModelHurtboxConfig = {
	OwnerId: number,
	Team: Team,
	Receive: Hurtbox.ReceiveCallback,
	Enabled: boolean?,
}

type ModelHurtboxData = {
	Hurtbox: Hurtbox,

	_box: ModelBox,
}

type ModelHurtboxPrototype = typeof(ModelHurtbox)

export type ModelHurtbox = typeof(setmetatable(
	{} :: ModelHurtboxData,
	{} :: ModelHurtboxPrototype
))

function ModelHurtbox.new(model: Model, config: ModelHurtboxConfig): ModelHurtbox
	local box = ModelBox.new(model)

	local data: ModelHurtboxData = {
		Hurtbox = Hurtbox.new({
			OwnerId = config.OwnerId,
			Team = config.Team,
			Center = box:GetCenter(),
			Size = box.Size,
			Receive = config.Receive,
			Enabled = config.Enabled,
		}),

		_box = box,
	}

	return setmetatable(data, ModelHurtbox)
end

-- Moves the hurtbox to where the model is now. Call it every frame, after the model has moved.
function ModelHurtbox.Update(self: ModelHurtbox): ()
	self.Hurtbox:MoveTo(self._box:GetCenter())
end

return ModelHurtbox
