--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local MockWorld = require(ReplicatedStorage.MockWorld.MockWorld)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local CollisionQueryFacade = require(RKMNControllerFolder.CollisionQuery.CollisionQueryFacade)
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local Direction = require(ReplicatedStorage.Data.Direction)

local tolerances = table.freeze({
	GroundCheckDistance = 0.5,
	WallCheckDistance = 0.5,
	SkinWidth = 0.1,
	MaxSlopeAngle = 45,
})

-- The parts have their own specs; these tests only check that the facade wires them together.
describe("CollisionQueryFacade", function()
	local world
	local character
	local body
	local query

	local function spawnFloor(topY)
		return world:SpawnPart({
			Size = Vector3.new(20, 1, 20),
			Position = Vector3.new(0, topY - 0.5, 0),
		})
	end

	local function spawnWall(faceX)
		local sign = if faceX >= 0 then 1 else -1
		return world:SpawnPart({
			Size = Vector3.new(1, 10, 10),
			Position = Vector3.new(faceX + sign * 0.5, 0, 0),
		})
	end

	beforeEach(function()
		world = MockWorld.new()
		character = world:SpawnCharacter()
		body = CollisionBody.new(character)
		body._footSize = Vector3.new(0.2, 0.1, 0.2)
		query = CollisionQueryFacade.new(world, character, body, tolerances)
	end)

	afterEach(function()
		if query then
			query:Destroy()
		end
		if world then
			world:Destroy()
		end
	end)

	describe("new", function()
		it("should throw when the character has no PrimaryPart", function()
			character.PrimaryPart = nil

			expect(function()
				CollisionQueryFacade.new(world, character, body, tolerances)
			end).toThrow("PrimaryPart")
		end)
	end)

	describe("UpdateState / IsGrounded", function()
		it("should start not grounded", function()
			expect(query:IsGrounded()).toBe(false)
		end)

		it("should become grounded after UpdateState with a floor below", function()
			spawnFloor(-1.3)

			query:UpdateState()

			expect(query:IsGrounded()).toBe(true)
		end)
	end)

	describe("CheckWallContact", function()
		it("should report contact with a nearby wall", function()
			spawnWall(1.3)

			expect(query:CheckWallContact(Direction.Right).Success).toBe(true)
		end)
	end)

	describe("GetSweepResolution", function()
		it("should stop short of a wall", function()
			spawnWall(2)

			local resolution = query:GetSweepResolution(Vector3.new(3, 0, 0))

			expect(resolution.SafeDelta.X).toBeCloseTo(0.9, 3)
			expect(resolution.SurfaceHits.HitWall).toBe(true)
		end)

		it("should remember the last resolution", function()
			expect(query:GetLastSweepResolution()).toBeNil()

			local resolution = query:GetSweepResolution(Vector3.new(0, 1, 0))

			expect(query:GetLastSweepResolution()).toBe(resolution)
		end)

		it("should only apply the ledge guard once enabled", function()
			spawnFloor(-1.3)
			query:UpdateState()

			local unguarded = query:GetSweepResolution(Vector3.new(15, 0, 0))
			query:SetLedgeGuard(true)
			local guarded = query:GetSweepResolution(Vector3.new(15, 0, 0))

			expect(unguarded.SurfaceHits.HitLedge).toBe(false)
			expect(guarded.SurfaceHits.HitLedge).toBe(true)
			expect(guarded.SafeDelta.X).toBeLessThan(10)
		end)
	end)

	describe("Destroy", function()
		it("should be safe to call twice", function()
			query:Destroy()

			expect(function()
				query:Destroy()
			end).never.toThrow()
		end)
	end)
end)
