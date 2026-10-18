--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ModelBox = require(ReplicatedStorage.Combat.Model.ModelBox)

-- A model with one root part, plus an optional second part to make the bounding box off-center.
local function makeModel(rootSize, rootPosition, extra)
	local model = Instance.new("Model")

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = rootSize
	root.Position = rootPosition
	root.Parent = model
	model.PrimaryPart = root

	if extra then
		local part = Instance.new("Part")
		part.Size = extra.Size
		part.Position = extra.Position
		part.Parent = model
	end

	return model
end

describe("ModelBox.new", function()
	it("takes its size from the model's bounding box on X and Y", function()
		local model = makeModel(Vector3.new(2, 4, 1), Vector3.new(0, 0, 0))

		local box = ModelBox.new(model)

		expect(box.Size).toEqual(Vector2.new(2, 4))
	end)

	it("covers every part of the model", function()
		local model = makeModel(Vector3.new(2, 2, 1), Vector3.new(0, 0, 0), {
			Size = Vector3.new(2, 2, 1),
			Position = Vector3.new(0, 4, 0),
		})

		local box = ModelBox.new(model)

		expect(box.Size).toEqual(Vector2.new(2, 6))
	end)

	it("rejects a model without a primary part", function()
		local model = Instance.new("Model")

		expect(function()
			ModelBox.new(model)
		end).toThrow()
	end)
end)

describe("ModelBox:GetCenter", function()
	it("is the middle of the model's box", function()
		local model = makeModel(Vector3.new(2, 2, 1), Vector3.new(10, 5, 0))

		local box = ModelBox.new(model)

		expect(box:GetCenter()).toEqual(Vector2.new(10, 5))
	end)

	it("is the middle of the whole box, not of the primary part", function()
		local model = makeModel(Vector3.new(2, 2, 1), Vector3.new(0, 0, 0), {
			Size = Vector3.new(2, 2, 1),
			Position = Vector3.new(0, 4, 0),
		})

		local box = ModelBox.new(model)

		expect(box:GetCenter()).toEqual(Vector2.new(0, 2))
	end)

	it("follows the model when it moves", function()
		local model = makeModel(Vector3.new(2, 2, 1), Vector3.new(0, 0, 0))
		local box = ModelBox.new(model)

		model:PivotTo(CFrame.new(30, 7, 0))

		expect(box:GetCenter()).toEqual(Vector2.new(30, 7))
	end)

	it("keeps the size measured at build time", function()
		local model = makeModel(Vector3.new(2, 2, 1), Vector3.new(0, 0, 0))
		local box = ModelBox.new(model)

		model.PrimaryPart.Size = Vector3.new(10, 10, 1)

		expect(box.Size).toEqual(Vector2.new(2, 2))
	end)
end)
