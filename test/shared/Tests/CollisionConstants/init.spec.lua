--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)

local function createPart(size: Vector3, position: Vector3): Part
	local part: Part = Instance.new("Part")
	part.Size = size
	part.Position = position
	part.Anchored = true
	return part
end

local function createCharacter(size: Vector3, position: Vector3): Model
    local model: Model = Instance.new("Model")
	local rootPart = createPart(size, position)
	rootPart.Parent = model
	model.PrimaryPart = rootPart
    local humanoid: Humanoid = Instance.new("Humanoid")
    humanoid.Parent = model

    return model
end

describe("CollisionConstants", function()
    local model: Model
    local characterSize: Vector3 = Vector3.new(4, 5, 2)
    local position: Vector3 = Vector3.zero

    beforeEach(function()
        model = createCharacter(characterSize, position)
    end)

    afterEach(function()
        model:Destroy()
    end)

	describe("new", function()
		it("returns a table with the CollisionConstants metatable", function()
			local constants = CollisionConstants.new(model)

			expect(constants).toBeDefined()
			expect(getmetatable(constants :: any)).toBe(CollisionConstants)
		end)

		it("sets HitboxSize to the model's extents size", function()
			local constants = CollisionConstants.new(model)

			expect(constants.HitboxSize).toEqual(model:GetExtentsSize())
		end)

		it("accounts for every part when computing HitboxSize", function()
            local extraPartSize: Vector3 = Vector3.new(2, 2, 2)
            local extraPartPosition: Vector3 = Vector3.new(10, 0, 0)
			local extraPart = createPart(extraPartSize, extraPartPosition)
			extraPart.Parent = model

			local constants = CollisionConstants.new(model)

			expect(constants.HitboxSize).toEqual(model:GetExtentsSize())
		end)

		it("returns a zero HitboxSize for an empty model", function()
			local emptyModel = Instance.new("Model")

			local constants = CollisionConstants.new(emptyModel)

			expect(constants.HitboxSize).toEqual(Vector3.zero)

			emptyModel:Destroy()
		end)

		it("sets the default GroundCheckDistance", function()
			expect(CollisionConstants.new(model).GroundCheckDistance).toBe(2)
		end)

		it("sets the default WallCheckDistance", function()
			expect(CollisionConstants.new(model).WallCheckDistance).toBe(2)
		end)

		it("sets the default MaxSlopeAngle", function()
			expect(CollisionConstants.new(model).MaxSlopeAngle).toBe(90)
		end)

		it("sets the default SkinWidth", function()
			expect(CollisionConstants.new(model).SkinWidth).toBe(2)
		end)
	end)

	describe("instances", function()
		it("creates independent instances", function()
			local a = CollisionConstants.new(model)
			local b = CollisionConstants.new(model)

			expect(a).never.toBe(b)

			a.SkinWidth = 10
			expect(b.SkinWidth).toBe(2)
		end)
	end)
end)
