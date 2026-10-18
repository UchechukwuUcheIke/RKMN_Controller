--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local ModelHurtbox = require(ReplicatedStorage.Combat.Hurtbox.ModelHurtbox)
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

local function makeModelHurtbox(model, overrides)
	local config = {
		OwnerId = 5,
		Team = Team.Player,
		Receive = function()
			return HitResult.Applied
		end,
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return ModelHurtbox.new(model, config)
end

describe("ModelHurtbox.new", function()
	it("builds a hurtbox the size of the model, on the model", function()
		local model = makeModel(Vector3.new(10, 5, 0))

		local hurtbox = makeModelHurtbox(model).Hurtbox

		expect(hurtbox:GetBounds().Size).toEqual(Vector2.new(2, 4))
		expect(hurtbox:GetBounds().Center).toEqual(Vector2.new(10, 5))
	end)

	it("passes the rest of the config to the hurtbox", function()
		local receive = function()
			return HitResult.Blocked
		end

		local hurtbox = makeModelHurtbox(makeModel(Vector3.zero), {
			OwnerId = 9,
			Team = Team.Neutral,
			Receive = receive,
			Enabled = false,
		}).Hurtbox

		expect(hurtbox.OwnerId).toBe(9)
		expect(hurtbox.Team).toBe(Team.Neutral)
		expect(hurtbox.Receive).toBe(receive)
		expect(hurtbox.Enabled).toBe(false)
	end)
end)

describe("ModelHurtbox:Update", function()
	it("moves the hurtbox to where the model is now", function()
		local model = makeModel(Vector3.new(0, 0, 0))
		local modelHurtbox = makeModelHurtbox(model)

		model:PivotTo(CFrame.new(8, 2, 0))
		modelHurtbox:Update()

		expect(modelHurtbox.Hurtbox:GetBounds().Center).toEqual(Vector2.new(8, 2))
		expect(modelHurtbox.Hurtbox:GetBounds().Size).toEqual(Vector2.new(2, 4))
	end)

	it("leaves the hurtbox behind until it is updated", function()
		local model = makeModel(Vector3.new(0, 0, 0))
		local modelHurtbox = makeModelHurtbox(model)

		model:PivotTo(CFrame.new(8, 2, 0))

		expect(modelHurtbox.Hurtbox:GetBounds().Center).toEqual(Vector2.new(0, 0))
	end)
end)
