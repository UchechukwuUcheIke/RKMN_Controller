--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local PhysicsResolverFacade = require(RKMNControllerFolder.PhysicsResolver.PhysicsResolverFacade)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local SurfaceHits = require(RKMNControllerFolder.SurfaceHits)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)
local Direction = require(ReplicatedStorage.Data.Direction)

local stats = table.freeze({
	JumpVelocity = 40,
	RiseGravity = 100,
	FallGravity = 200,
	CutGravity = 400,
	FallSpeed = 120,
})

local function createCharacterModel()
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

local function makeResolution(safeDelta, hits)
	local castRecord = DiagnosticCastRecord.fromBlockcast(false, CFrame.new(), Vector3.one, safeDelta)
	return SweepResolution.new(castRecord, safeDelta, hits)
end

-- Stands in for CollisionQueryFacade: records the requested delta and returns a canned resolution.
local function createCollisionQueryStub(isGrounded, resolution)
	local stub = { requestedDeltas = {} }

	function stub:IsGrounded()
		return isGrounded
	end

	function stub:GetSweepResolution(delta)
		table.insert(self.requestedDeltas, delta)
		return resolution or makeResolution(delta, SurfaceHits.new())
	end

	return stub
end

-- The parts have their own specs; these tests only check that the facade wires them together.
describe("PhysicsResolverFacade", function()
	local characterModel
	local rootPart
	local collisionQuery
	local resolver

	local function build(isGrounded, resolution)
		collisionQuery = createCollisionQueryStub(isGrounded, resolution)
		resolver = PhysicsResolverFacade.new(characterModel, stats, collisionQuery)
	end

	beforeEach(function()
		characterModel = createCharacterModel()
		rootPart = characterModel:FindFirstChild("HumanoidRootPart")
	end)

	afterEach(function()
		if resolver then
			resolver:Destroy()
			resolver = nil
		end
		characterModel:Destroy()
	end)

	describe("new", function()
		it("should throw if the model has no HumanoidRootPart", function()
			rootPart:Destroy()

			expect(function()
				PhysicsResolverFacade.new(characterModel, stats, createCollisionQueryStub(false))
			end).toThrow()
		end)

		it("should throw if the model has no Humanoid", function()
			characterModel:FindFirstChild("Humanoid"):Destroy()

			expect(function()
				PhysicsResolverFacade.new(characterModel, stats, createCollisionQueryStub(false))
			end).toThrow()
		end)

		it("should anchor the root part", function()
			build(false)

			expect(rootPart.Anchored).toBe(true)
		end)

		it("should start at zero velocity facing right", function()
			build(false)

			expect(resolver:GetVelocity()).toEqual(Vector3.zero)
			expect(resolver:GetFacingDirection()).toBe(Direction.Right)
		end)
	end)

	describe("Destroy", function()
		it("should un-anchor the root part", function()
			build(false)

			resolver:Destroy()

			expect(rootPart.Anchored).toBe(false)
		end)
	end)

	describe("MoveInDirection", function()
		it("should set the target velocity and facing from direction and speed", function()
			build(true)

			resolver:MoveInDirection(Direction.Left, 20)
			resolver:Resolve(0.1)

			expect(resolver:GetVelocity().X).toBeCloseTo(-20, 4)
			expect(resolver:GetFacingDirection()).toBe(Direction.Left)
		end)
	end)

	describe("ApplyJumpImpulse", function()
		it("should set Y velocity to the jump velocity and keep X", function()
			build(false)
			resolver:SetTargetXVelocity(12, Direction.Right)
			resolver:Resolve(0.1)

			resolver:ApplyJumpImpulse()

			expect(resolver:GetVelocity().X).toBeCloseTo(12, 4)
			expect(resolver:GetVelocity().Y).toBe(40)
		end)

		it("should clear an earlier rise cut", function()
			build(false)
			resolver:ApplyJumpImpulse()
			resolver:CutRise()
			resolver:ApplyJumpImpulse()

			resolver:Resolve(0.1)

			-- Rise gravity (100): 40 - 100 * 0.1 = 30. Cut gravity (400) would give 0.
			expect(resolver:GetVelocity().Y).toBeCloseTo(30, 4)
		end)
	end)

	describe("CutRise", function()
		it("should switch a rising character to cut gravity", function()
			build(false)
			resolver:ApplyJumpImpulse()
			resolver:CutRise()

			resolver:Resolve(0.1)

			expect(resolver:GetVelocity().Y).toBeCloseTo(0, 4)
		end)
	end)

	describe("SetFallSpeedOverride", function()
		it("should cap the fall speed", function()
			build(false)
			resolver:SetFallSpeedOverride(5)

			for _ = 1, 20 do
				resolver:Resolve(1)
			end

			expect(resolver:GetVelocity().Y).toBeCloseTo(-5, 4)
		end)
	end)

	describe("Resolve", function()
		it("should apply horizontal target, then gravity, then sweep the averaged delta", function()
			build(false)
			resolver:SetTargetXVelocity(20, Direction.Right)

			resolver:Resolve(0.1)

			-- Y: 0 -> -20 (fall gravity 200 * 0.1); averaged over the frame -> -10 * 0.1 = -1
			expect(resolver:GetVelocity().X).toBeCloseTo(20, 4)
			expect(resolver:GetVelocity().Y).toBeCloseTo(-20, 4)
			local delta = collisionQuery.requestedDeltas[1]
			expect(delta.X).toBeCloseTo(2, 4)
			expect(delta.Y).toBeCloseTo(-1, 4)
		end)

		it("should move the root part by the safe delta", function()
			local resolution = makeResolution(Vector3.new(0.33, -1.67, 0), SurfaceHits.new())
			build(false, resolution)

			resolver:Resolve(1 / 60)

			local position = rootPart.CFrame.Position
			expect(position.X).toBeCloseTo(0.33, 4)
			expect(position.Y).toBeCloseTo(10 - 1.67, 4)
		end)

		it("should zero the blocked velocity after the sweep", function()
			build(false, makeResolution(Vector3.zero, SurfaceHits.new(false, true, false)))
			resolver:SetTargetXVelocity(20, Direction.Right)

			resolver:Resolve(0.1)

			expect(resolver:GetVelocity().X).toBe(0)
		end)

		it("should not accumulate fall speed while grounded", function()
			build(true)

			resolver:Resolve(0.1)
			resolver:Resolve(0.1)

			expect(resolver:GetVelocity().Y).toBe(0)
		end)
	end)
end)
