--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local HurtboxFolder = CombatFolder.Hurtbox
local DamagePayload = require(DataFolder.DamagePayload)
local Health = require(CombatFolder.Health)
local HitResult = require(HurtboxFolder.HitResult)
local Hurtbox = require(HurtboxFolder.Hurtbox)
local HurtboxRegistry = require(HurtboxFolder.HurtboxRegistry)
local ModelHurtbox = require(HurtboxFolder.ModelHurtbox)
local Team = require(DataFolder.Team)

type DamagePayload = DamagePayload.DamagePayload
type Health = Health.Health
type HitResult = HitResult.HitResult
type Hurtbox = Hurtbox.Hurtbox
type HurtboxRegistry = HurtboxRegistry.HurtboxRegistry

local DummyEnemy = {}
DummyEnemy.__index = DummyEnemy

type DummyEnemyData = {
	Health: Health,

	_model: Model,
	_hurtbox: Hurtbox,
	_hurtboxRegistry: HurtboxRegistry,
}

type DummyEnemyPrototype = typeof(DummyEnemy)

export type DummyEnemy = typeof(setmetatable(
	{} :: DummyEnemyData,
	{} :: DummyEnemyPrototype
))

function DummyEnemy.new(
	model: Model,
	ownerId: number,
	maxHealth: number,
	hurtboxRegistry: HurtboxRegistry
): DummyEnemy
	local enemy: DummyEnemy

	local modelHurtbox = ModelHurtbox.new(model, {
		OwnerId = ownerId,
		Team = Team.Enemy :: Team.Team,
		Receive = function(damage: DamagePayload): HitResult
			return enemy:_receive(damage)
		end,
	})

	local data: DummyEnemyData = {
		Health = Health.new(maxHealth),

		_model = model,
		_hurtbox = modelHurtbox.Hurtbox,
		_hurtboxRegistry = hurtboxRegistry,
	}

	enemy = setmetatable(data, DummyEnemy)
	hurtboxRegistry:Register(modelHurtbox.Hurtbox)
	return enemy
end

function DummyEnemy._receive(self: DummyEnemy, damage: DamagePayload): HitResult
	if self.Health:IsDepleted() then
		return HitResult.Ignored :: HitResult
	end

	self.Health:TakeDamage(damage.Amount)
	if not self.Health:IsDepleted() then
		return HitResult.Applied :: HitResult
	end

	self:Destroy()
	return HitResult.Killed :: HitResult
end

function DummyEnemy.Destroy(self: DummyEnemy): ()
	self._hurtboxRegistry:Unregister(self._hurtbox)
	self._model:Destroy()
end

return DummyEnemy
