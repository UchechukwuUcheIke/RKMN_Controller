--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)
local Direction = require(ReplicatedStorage.Data.Direction)
local ModelHitbox = require(ReplicatedStorage.Combat.Hitbox.ModelHitbox)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local function makeModel(position)
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 4, 1)
	root.Position = position
	root.Parent = model
	model.PrimaryPart = root
	return model
end

local function makeModelHitbox(model, overrides)
	local config = {
		OwnerId = 5,
		Team = Team.Enemy,
		Damage = DamageTemplate.new({ Amount = 2 }),
		Direction = Direction.Left,
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return ModelHitbox.new(model, config)
end

describe("ModelHitbox.new", function()
	it("builds a hitbox the size of the model, on the model", function()
		local model = makeModel(Vector3.new(10, 5, 0))

		local modelHitbox = makeModelHitbox(model)

		expect(modelHitbox.Hitbox.Size).toEqual(Vector2.new(2, 4))
		expect(modelHitbox.Hitbox:GetCenter()).toEqual(Vector2.new(10, 5))
	end)

	it("passes the rest of the config to the hitbox", function()
		local model = makeModel(Vector3.zero)
		local damage = DamageTemplate.new({ Amount = 7 })
		local onHit = function() end

		local hitbox = makeModelHitbox(model, {
			OwnerId = 9,
			Team = Team.Neutral,
			Damage = damage,
			Direction = Direction.Right,
			OnHit = onHit,
			Enabled = false,
		}).Hitbox

		expect(hitbox.OwnerId).toBe(9)
		expect(hitbox.Team).toBe(Team.Neutral)
		expect(hitbox.Damage).toBe(damage)
		expect(hitbox.Direction).toBe(Direction.Right)
		expect(hitbox.OnHit).toBe(onHit)
		expect(hitbox.Enabled).toBe(false)
	end)

	it("starts with nothing to sweep", function()
		local modelHitbox = makeModelHitbox(makeModel(Vector3.new(3, 3, 0)))

		expect(modelHitbox.Hitbox:GetPreviousCenter()).toEqual(modelHitbox.Hitbox:GetCenter())
	end)
end)

describe("ModelHitbox:Update", function()
	it("moves the hitbox to the model and remembers where it was", function()
		local model = makeModel(Vector3.new(0, 0, 0))
		local modelHitbox = makeModelHitbox(model)

		model:PivotTo(CFrame.new(8, 2, 0))
		modelHitbox:Update()

		expect(modelHitbox.Hitbox:GetCenter()).toEqual(Vector2.new(8, 2))
		expect(modelHitbox.Hitbox:GetPreviousCenter()).toEqual(Vector2.new(0, 0))
	end)

	it("does nothing when the model has not moved", function()
		local modelHitbox = makeModelHitbox(makeModel(Vector3.new(4, 4, 0)))

		modelHitbox:Update()

		expect(modelHitbox.Hitbox:GetCenter()).toEqual(Vector2.new(4, 4))
		expect(modelHitbox.Hitbox:GetPreviousCenter()).toEqual(Vector2.new(4, 4))
	end)
end)
