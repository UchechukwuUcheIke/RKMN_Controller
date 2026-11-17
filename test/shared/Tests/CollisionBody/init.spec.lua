--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local CollisionBody = require(RKMNControllerFolder.CollisionBody)

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
    rootPart.Name = "HumanoidRootPart"
    rootPart.Parent = model
    model.PrimaryPart = rootPart

    return model
end

describe("CollisionBody", function()
    local model: Model
    local rootPart: BasePart
    local characterSize: Vector3 = Vector3.new(4, 5, 2)

    beforeEach(function()
        model = createCharacter(characterSize, Vector3.zero)
        rootPart = model.PrimaryPart :: BasePart
    end)

    afterEach(function()
        model:Destroy()
    end)

    describe("new", function()
        it("returns a table with the CollisionBody metatable", function()
            local body = CollisionBody.new(model)

            expect(getmetatable(body :: any)).toBe(CollisionBody)
        end)

        it("sets BodySize to the model's extents size", function()
            local body = CollisionBody.new(model)

            expect(body:GetBodySize()).toEqual(model:GetExtentsSize())
        end)

        it("accounts for every part when computing BodySize", function()
            local extraPart = createPart(Vector3.new(2, 2, 2), Vector3.new(10, 0, 0))
            extraPart.Parent = model

            local body = CollisionBody.new(model)

            expect(body:GetBodySize()).toEqual(model:GetExtentsSize())
        end)

        it("sets HalfWidth to half the body width", function()
            expect(CollisionBody.new(model):GetHalfWidth()).toBe(2)
        end)

        it("makes the foot as wide and deep as the body and 0.1 tall", function()
            local body = CollisionBody.new(model)

            expect(body:GetFootSize()).toEqual(Vector3.new(4, 0.1, 2))
        end)

        it("throws when the model has no HumanoidRootPart", function()
            rootPart.Name = "Torso"

            expect(function()
                CollisionBody.new(model)
            end).toThrow("HumanoidRootPart")
        end)
    end)

    describe("GetBodyCFrame", function()
        it("follows the root part", function()
            local body = CollisionBody.new(model)

            rootPart.CFrame = CFrame.new(10, 20, 30)

            expect(body:GetBodyCFrame().Position).toEqual(Vector3.new(10, 20, 30))
        end)
    end)

    describe("GetFootCFrame", function()
        it("sits at the bottom of the body", function()
            local body = CollisionBody.new(model)

            expect(body:GetFootCFrame().Position.Y).toBeCloseTo(-2.5 + 0.05, 5)
        end)

        it("follows the root part", function()
            local body = CollisionBody.new(model)

            rootPart.CFrame = CFrame.new(10, 20, 30)

            expect(body:GetFootCFrame().Position.X).toBeCloseTo(10, 5)
            expect(body:GetFootCFrame().Position.Y).toBeCloseTo(20 - 2.5 + 0.05, 5)
            expect(body:GetFootCFrame().Position.Z).toBeCloseTo(30, 5)
        end)
    end)

    describe("GetHalfExtentAlongDirection", function()
        it("returns half the size along each axis", function()
            local body = CollisionBody.new(model)

            expect(body:GetHalfExtentAlongDirection(Vector3.xAxis)).toBeCloseTo(2, 5)
            expect(body:GetHalfExtentAlongDirection(Vector3.yAxis)).toBeCloseTo(2.5, 5)
            expect(body:GetHalfExtentAlongDirection(Vector3.zAxis)).toBeCloseTo(1, 5)
        end)

        it("accounts for the character's facing", function()
            local body = CollisionBody.new(model)

            rootPart.CFrame = CFrame.Angles(0, math.rad(90), 0)

            expect(body:GetHalfExtentAlongDirection(Vector3.xAxis)).toBeCloseTo(1, 5)
            expect(body:GetHalfExtentAlongDirection(Vector3.zAxis)).toBeCloseTo(2, 5)
        end)
    end)

    describe("instances", function()
        it("creates independent instances", function()
            local a = CollisionBody.new(model)
            local b = CollisionBody.new(model)

            expect(a).never.toBe(b)
        end)
    end)
end)
