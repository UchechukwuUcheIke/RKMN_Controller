local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MockWorld = require(ReplicatedStorage:WaitForChild("MockWorld"):WaitForChild("MockWorld"))

return function()
    describe("MockWorld Class", function()
        local world

        -- Setup a fresh world before every test
        beforeEach(function()
            world = MockWorld.new()
        end)

        -- Clean up after every test to prevent memory leaks
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
                Position = expectedPosition
            })

            expect(part).to.be.ok()
            expect(part.ClassName).to.equal("Part")
            expect(part.Size).to.equal(expectedSize)
            expect(part.Position).to.equal(expectedPosition)
        end)

        it("should spawn a fully rigged character dummy", function()
            local character = world:SpawnCharacter()

            expect(character).to.be.ok()
            expect(character.ClassName).to.equal("Model")
            
            -- Verify PrimaryPart
            expect(character.PrimaryPart).to.be.ok()
            expect(character.PrimaryPart.Name).to.equal("HumanoidRootPart")
            
            -- Verify Humanoid exists
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            expect(humanoid).to.be.ok()
        end)

        it("should clear all spawned instances", function()
            world:SpawnPart()
            world:SpawnCharacter()
            
            expect(#world:GetChildren() > 0).to.equal(true)

            world:Clear()

            expect(#world:GetChildren()).to.equal(0)
        end)

        it("should successfully delegate WorldModel methods like Raycast", function()
            local targetPart = world:SpawnPart({
                Size = Vector3.new(10, 1, 10),
                Position = Vector3.new(0, 5, 0)
            })

            -- Perform a raycast pointing straight up
            local origin = Vector3.zero
            local direction = Vector3.new(0, 10, 0)
            
            -- Call Raycast directly on the MockWorld wrapper
            local result = world:Raycast(origin, direction)

            expect(result).to.be.ok()
            expect(result.Instance).to.equal(targetPart)
        end)
    end)
end
