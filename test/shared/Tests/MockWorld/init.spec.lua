local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local MockWorld = require(ReplicatedStorage:WaitForChild("MockWorld"):WaitForChild("MockWorld"))

describe("MockWorld Class", function()
    local world

    beforeEach(function()
        world = MockWorld.new()
    end)

    afterEach(function()
        if world then
            world:Destroy()
        end
    end)

    it("should spawn an anchored part with applied properties", function()
        local expectedSize = Vector3.new(5, 5, 5)
        local expectedPosition = Vector3.new(0, 10, 0)

        local part = world:SpawnPart({
            Size = expectedSize,
            Position = expectedPosition,
        })

        expect(part).toBeDefined()
        expect(part.ClassName).toBe("Part")
        expect(part.Anchored).toBe(true)
        expect(part.Size).toEqual(expectedSize)
        expect(part.Position).toEqual(expectedPosition)
    end)

    it("should spawn a fully rigged character dummy", function()
        local character = world:SpawnCharacter()

        expect(character).toBeDefined()
        expect(character.ClassName).toBe("Model")

        expect(character.PrimaryPart).toBeDefined()
        expect(character.PrimaryPart.Name).toBe("HumanoidRootPart")

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        expect(humanoid).toBeDefined()
    end)

    it("should clear all spawned instances", function()
        world:SpawnPart()
        world:SpawnCharacter()

        expect(#world:GetChildren()).toBeGreaterThan(0)

        world:Clear()

        expect(#world:GetChildren()).toBe(0)
    end)

    it("should successfully delegate WorldModel methods like Raycast", function()
        local targetPart = world:SpawnPart({
            Size = Vector3.new(10, 1, 10),
            Position = Vector3.new(0, 5, 0),
        })

        local origin = Vector3.zero
        local direction = Vector3.new(0, 10, 0)

        local result = world:Raycast(origin, direction)

        expect(result).toBeDefined()
        expect(result.Instance).toBe(targetPart)
    end)
end)