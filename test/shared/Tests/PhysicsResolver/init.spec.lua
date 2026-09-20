--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage:WaitForChild("RKMNController")
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)
local Direction = require(RKMNControllerFolder.Direction)
local MovementStats = require(RKMNControllerFolder.MovementStats)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local MockUtils = require(script.Parent.Parent.Parent.TestUtils.MockUtils) -- todo: adjust path

local JestGlobals = require(game:GetService("ReplicatedStorage").DevPackages.JestGlobals) -- adjust path
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local jest = JestGlobals.jest

local createMockClass = MockUtils.createMockClass

type MovementStats = MovementStats.MovementStats
type CollisionQuery = CollisionQuery.CollisionQuery
type SweepResolution = SweepResolution.SweepResolution
type MethodMap = MockUtils.MethodMap
type MockResult<T> = MockUtils.MockResult<T>
type PhysicsResolver = PhysicsResolver.PhysicsResolver


local function createCharacterModel(): Model
	local model = Instance.new("Model")

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Anchored = false
	rootPart.CFrame = CFrame.new(0, 10, 0)
	rootPart.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	return model
end

local function createMockedMovementStats(): MovementStats
    local mockResult: MockResult<MovementStats> = createMockClass(MovementStats)
    local mockedInstance: MovementStats = mockResult.Instance
    return mockedInstance
end

local function createMockedCollisionQuery(): CollisionQuery
    local mockResult: MockResult<CollisionQuery> = createMockClass(CollisionQuery)
    local mockedInstance: CollisionQuery = mockResult.Instance
    return mockedInstance
end

describe("PhysicsResolver.new Assertions", function()
	local characterModel: Model
    local movementStats: MovementStats
    local collisionQuery: CollisionQuery

	beforeEach(function()
		characterModel = createCharacterModel()
        movementStats = createMockedMovementStats()
        collisionQuery = createMockedCollisionQuery()
	end)

	afterEach(function()
		characterModel:Destroy()
        movementStats:Destroy()
        collisionQuery:Destroy()
	end)

	it("throws if the model has no HumanoidRootPart", function()
		local rootPart = characterModel:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart:Destroy()
		end

		expect(function()
			PhysicsResolver.new(characterModel, movementStats, collisionQuery)
		end).toThrow()
	end)

	it("throws if the model has no Humanoid", function()
		local humanoid = characterModel:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:Destroy()
		end

		expect(function()
			PhysicsResolver.new(characterModel, movementStats, collisionQuery)
		end).toThrow()
	end)
end)

describe("PhysicsResolver.new", function()
	local characterModel: Model
    local movementStats: MovementStats
    local collisionQuery: CollisionQuery
    local physicsResolver: PhysicsResolver

	beforeEach(function()
		characterModel = createCharacterModel()
        movementStats = createMockedMovementStats()
        collisionQuery = createMockedCollisionQuery()

        expect(function()
            physicsResolver = PhysicsResolver.new(characterModel, movementStats,  collisionQuery)
        end).never.toThrow()
	end)

	afterEach(function()
		characterModel:Destroy()
        movementStats:Destroy()
        collisionQuery:Destroy()
        physicsResolver:Destroy()

	end)

	it("anchors the root part so Roblox's own physics never fights the resolver", function()
		local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart

		expect(rootPart.Anchored).toBe(true)
	end)

	it("disables every HumanoidStateType so the default Humanoid controller can't interfere", function()
		local humanoid = characterModel:FindFirstChild("Humanoid") :: Humanoid

		for _, state in Enum.HumanoidStateType:GetEnumItems() do
			expect(humanoid:GetStateEnabled(state)).toBe(false)
		end
	end)

	it("starts at zero velocity, facing Direction.Right, with zero target velocity", function()
		expect(physicsResolver.Velocity).toEqual(Vector3.zero)
		expect(physicsResolver.FacingDirection).toBe(Direction.Right)
		expect(physicsResolver.TargetXVelocity).toBe(0)
	end)

	it("un-anchors the root part on Destroy", function()
		local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart
		physicsResolver:Destroy()
		expect(rootPart.Anchored).toBe(false)
	end)
end)

describe("PhysicsResolver:SetTargetXVelocity", function()
	local characterModel: Model
    local movementStats: MovementStats
    local collisionQuery: CollisionQuery
    local physicsResolver: PhysicsResolver

    beforeEach(function()
		characterModel = createCharacterModel()
        movementStats = createMockedMovementStats()
        collisionQuery = createMockedCollisionQuery()

        expect(function()
            physicsResolver = PhysicsResolver.new(characterModel, movementStats,  collisionQuery)
        end).never.toThrow()
	end)

	afterEach(function()
		characterModel:Destroy()
        movementStats:Destroy()
        collisionQuery:Destroy()
        physicsResolver:Destroy()
	end)

	it("updates TargetXVelocity", function()
		physicsResolver:SetTargetXVelocity(25, Direction.Right)
		expect(physicsResolver.TargetXVelocity).toBe(25)
	end)

	it("updates FacingDirection when a real direction is given", function()
		physicsResolver:SetTargetXVelocity(-25, Direction.Left)
		expect(physicsResolver.FacingDirection).toBe(Direction.Left)
	end)

	it("leaves FacingDirection unchanged when Direction.None is given", function()
		physicsResolver:SetTargetXVelocity(10, Direction.Right)
		physicsResolver:SetTargetXVelocity(0, Direction.None)

		expect(physicsResolver.FacingDirection).toBe(Direction.Right)
	end)
end)
--[[
describe("PhysicsResolver gravity integration", function()
    local characterModel: Model
    local movementStats: MovementStats
    local collisionQuery: CollisionQuery
    local physicsResolver: PhysicsResolver

    local function createMockedMovementStats(): MovementStats
        local mockResult: MockResult<CollisionQuery> = createMockClass(MovementStats)
        local mockedInstance: CollisionQuery = mockResult.Instance
        mockedInstance.Gravity = 100
        mockedInstance.MaxFallSpeed = 120

        return mockedInstance
    end


    beforeEach(function()
		characterModel = makeCharacterModel()
        movementStats = createMockedMovementStats()
        collisionQuery = createMockedCollisionQuery()

        expect(function()
            physicsResolver = PhysicsResolver.new(characterModel, movementStats,  collisionQuery)
        end).never.toThrow()
	end)

	afterEach(function()
		characterModel:Destroy()
        movementStats:Destroy()
        movementStats = nil
        collisionQuery:Destroy()
        collisionQuery = nil
        physicsResolver:Destroy()
        physicsResolver = nil

	end)

	it("reduces Y velocity by Gravity * dt per tick", function()
		physicsResolver:_applyGravity(0.1)
		expect(physicsResolver.Velocity.Y).toBeCloseTo(-10, 4)
	end)

	it("clamps fall speed at -MaxFallSpeed instead of accelerating forever", function()
		for _ = 1, 50 do
			physicsResolver:_applyGravity(1)
		end
		expect(physicsResolver.Velocity.Y).toBeCloseTo(-120, 4)
	end)
  
	it("never lets gravity touch X or Z", function()
		physicsResolver.Velocity = Vector3.new(42, 0, 0)
		physicsResolver:_applyGravity(0.1)
		expect(physicsResolver.Velocity.X).toBe(42)
		expect(physicsResolver.Velocity.Z).toBe(0)
	end)
end)

describe("PhysicsResolver horizontal movement", function()
	local characterModel: Model
	local resolver: any

	beforeEach(function()
		characterModel = makeCharacterModel()
		resolver = PhysicsResolver.new(characterModel, makeMovementStats(), makeFakeCollisionQuery(makeSweepResolution()))
	end)

	afterEach(function()
		resolver:Destroy()
		characterModel:Destroy()
	end)

	it("snaps X velocity straight to TargetXVelocity - no acceleration curve", function()
		resolver:SetTargetXVelocity(60, Direction.Right)
		resolver.Velocity = Vector3.new(0, -5, 0)

		resolver:_applyHorizontalMovement()

		expect(resolver.Velocity.X).toBe(60)
		expect(resolver.Velocity.Y).toBe(-5) -- untouched by this method
		expect(resolver.Velocity.Z).toBe(0)
	end)
end)

-- ---------------------------------------------------------------------------
-- _resolveVelocity: collision response + position update
-- ---------------------------------------------------------------------------

describe("PhysicsResolver:_resolveVelocity", function()
	local characterModel: Model
	local resolver: any

	beforeEach(function()
		characterModel = makeCharacterModel()
		resolver = PhysicsResolver.new(characterModel, makeMovementStats(), makeFakeCollisionQuery(makeSweepResolution()))
		resolver.Velocity = Vector3.new(30, -20, 0)
	end)

	afterEach(function()
		resolver:Destroy()
		characterModel:Destroy()
	end)

	it("zeroes X velocity on a wall hit but leaves Y alone", function()
		local sweep = makeSweepResolution({ hitWall = true, safeDelta = Vector3.new(2, 0, 0) })
		resolver:_resolveVelocity(sweep)

		expect(resolver.Velocity.X).toBe(0)
		expect(resolver.Velocity.Y).toBe(-20)
	end)

	it("zeroes Y velocity on a floor hit but leaves X alone", function()
		local sweep = makeSweepResolution({ hitFloor = true, safeDelta = Vector3.new(0, -1, 0) })
		resolver:_resolveVelocity(sweep)

		expect(resolver.Velocity.X).toBe(30)
		expect(resolver.Velocity.Y).toBe(0)
	end)

	it("leaves velocity untouched when neither a wall nor a floor was hit", function()
		local sweep = makeSweepResolution({ safeDelta = Vector3.new(0.5, -0.33, 0) })
		resolver:_resolveVelocity(sweep)

		expect(resolver.Velocity.X).toBe(30)
		expect(resolver.Velocity.Y).toBe(-20)
	end)

	it("moves the root part by exactly safeDelta, not by the requested velocity", function()
		local rootPart = characterModel:FindFirstChild("HumanoidRootPart") :: BasePart
		local startPosition = rootPart.CFrame.Position
		local sweep = makeSweepResolution({ safeDelta = Vector3.new(1, 0, 0) })

		resolver:_resolveVelocity(sweep)

		-- The whole point of a swept collision clamp is that safeDelta can be smaller
		-- than Velocity * dt would have been - so we check against safeDelta directly,
		-- not against what Velocity implies.
		local moved = rootPart.CFrame.Position - startPosition
		expect(moved.X).toBeCloseTo(1, 4)
		expect(moved.Y).toBeCloseTo(0, 4)
		expect(moved.Z).toBeCloseTo(0, 4)
	end)
end)

-- ---------------------------------------------------------------------------
-- Resolve: full tick, through the public API
-- ---------------------------------------------------------------------------

describe("PhysicsResolver:Resolve (full tick)", function()
	local characterModel: Model
	local resolver: any

	beforeEach(function()
		characterModel = makeCharacterModel()
	end)

	afterEach(function()
		if resolver then
			resolver:Destroy()
		end
		characterModel:Destroy()
	end)

	it("KNOWN BUG: currently errors instead of resolving a tick", function()
		-- self:_sweepForCollisions(self, dt) inside Resolve() passes `self` twice: the
		-- colon call already supplies it implicitly, then it's passed again explicitly.
		-- That shifts every later argument over by one, so `dt` inside
		-- _sweepForCollisions actually receives the PhysicsResolver instance instead of
		-- a number, and `self.Velocity * dt` multiplies a Vector3 by a table.
		--
		-- This test documents the bug as it stands today. Once the call site is fixed
		-- to `self:_sweepForCollisions(dt)`, delete this test and use the one commented
		-- out below instead.
		resolver = PhysicsResolver.new(characterModel, makeMovementStats(), makeFakeCollisionQuery(makeSweepResolution()))
		resolver:SetTargetXVelocity(20, Direction.Right)

		expect(function()
			resolver:Resolve(1 / 60)
		end).toThrow()
	end)

	--[[ Once the self-argument bug above is fixed, use this instead:

	it("applies horizontal target velocity, then gravity, then clamps to the swept delta", function()
		local fakeCollisionQuery = makeFakeCollisionQuery(
			makeSweepResolution({ safeDelta = Vector3.new(0.33, -1.67, 0) })
		)
		resolver = PhysicsResolver.new(characterModel, makeMovementStats({ Gravity = 100 }), fakeCollisionQuery)
		resolver:SetTargetXVelocity(20, Direction.Right)

		resolver:Resolve(1 / 60)

		expect(resolver.Velocity.X).toBeCloseTo(20, 4)
		expect(resolver.Velocity.Y).toBeCloseTo(-100 * (1 / 60), 4)
		expect(fakeCollisionQuery.GetSweepResolution).toHaveBeenCalled()
	end)

end)
]]--

