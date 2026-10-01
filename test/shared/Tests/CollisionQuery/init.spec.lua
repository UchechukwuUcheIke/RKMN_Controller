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
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local Direction = require(RKMNControllerFolder.Direction)

--[[
	Test layout. MockWorld:SpawnCharacter() gives a 2x2x1 HumanoidRootPart at the origin, so
	CollisionConstants.new() derives:
	  - Hitbox: 2 x 2 x 1 at the origin -> x = -1..1, y = -1..1
	  - HalfWidth = 1

	Tuning values and the foot are overridden in makeConstants for these tests:
	  - Foot: 0.2 x 0.1 x 0.2, bottom face at y = -1.0 (narrow so tilted slabs don't clip it)
	  - Ground reach = 0.5 + 0.1 = 0.6 -> floors with a top between y = -1.0 and -1.6 count
	  - Wall ray starts at x = +-1, reach 0.6 -> wall faces between 1.0 and 1.6 count
	  - SkinWidth = 0.1, MaxSlopeAngle = 45

	Blockcast ignores parts it initially overlaps, so every test leaves a gap between the
	cast shape and the geometry it should hit.
]]
local function makeConstants(character)
	local constants = CollisionConstants.new(character)

	-- Foot box sits at the bottom of the hitbox, narrow for the slope tests
	constants.FootSize = Vector3.new(0.2, 0.1, 0.2)
	constants.FootCFrame = constants.HitboxCFrame * CFrame.new(0, -constants.HitboxSize.Y / 2 + 0.05, 0)

	constants.GroundCheckDistance = 0.5
	constants.WallCheckDistance = 0.5
	constants.SkinWidth = 0.1
	constants.MaxSlopeAngle = 45

	return constants
end

describe("CollisionQuery", function()
	local world
	local character
	local constants
	local query

	-- Flat floor whose top face is at `topY`
	local function spawnFloor(topY)
		return world:SpawnPart({
			Size = Vector3.new(20, 1, 20),
			Position = Vector3.new(0, topY - 0.5, 0),
		})
	end

	-- Wall whose face nearest the character is at x = faceX (extends away from origin)
	local function spawnWall(faceX)
		local sign = if faceX >= 0 then 1 else -1
		return world:SpawnPart({
			Size = Vector3.new(1, 10, 10),
			Position = Vector3.new(faceX + sign * 0.5, 0, 0),
		})
	end

	-- Slab tilted about Z whose top face passes through `surfacePoint`.
	-- Top-face normal is (-sin a, cos a, 0).
	local function spawnSlab(surfacePoint, angleDegrees)
		local angle = math.rad(angleDegrees)
		local thickness = 1
		local normal = Vector3.new(-math.sin(angle), math.cos(angle), 0)
		local center = surfacePoint - normal * (thickness / 2)

		return world:SpawnPart({
			Size = Vector3.new(20, thickness, 20),
			CFrame = CFrame.new(center) * CFrame.Angles(0, 0, angle),
		})
	end

	local function expectVector(actual, expected)
		expect(actual.X).toBeCloseTo(expected.X, 3)
		expect(actual.Y).toBeCloseTo(expected.Y, 3)
		expect(actual.Z).toBeCloseTo(expected.Z, 3)
	end

	local function expectResolution(resolution, expectedDelta, expectedHitFloor, expectedHitWall)
		expectVector(resolution.safeDelta, expectedDelta)
		expect(resolution.hitFloor).toBe(expectedHitFloor)
		expect(resolution.hitWall).toBe(expectedHitWall)
	end

	beforeEach(function()
		world = MockWorld.new()
		character = world:SpawnCharacter()
		constants = makeConstants(character)
		query = CollisionQuery.new(world, character, constants)
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
		it("should start in a not-grounded state", function()
			expect(query:IsGrounded()).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
			expect(query.FloorNormal == Vector3.zero).toBe(true)
			expect(query.MovingPlatformDelta == CFrame.identity).toBe(true)
		end)

		it("should throw when the character has no PrimaryPart", function()
			character.PrimaryPart = nil

			expect(function()
				CollisionQuery.new(world, character, constants)
			end).toThrow("PrimaryPart")
		end)
	end)

	describe("UpdateState / IsGrounded", function()
		it("should not be grounded when there is no floor", function()
			query:UpdateState()

			expect(query:IsGrounded()).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
		end)

		it("should be grounded on a floor within check distance", function()
			local floor = spawnFloor(-1.3)

			query:UpdateState()

			expect(query:IsGrounded()).toBe(true)
			expect(query.CurrentFloorPart).toBe(floor)
			expectVector(query.FloorNormal, Vector3.yAxis)
		end)

		it("should not be grounded when the floor is beyond check distance", function()
			spawnFloor(-2.0)

			query:UpdateState()

			expect(query:IsGrounded()).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
		end)

		it("should be grounded on a slope below the max slope angle", function()
			local slope = spawnSlab(Vector3.new(0, -1.4, 0), 30)

			query:UpdateState()

			expect(query:IsGrounded()).toBe(true)
			expect(query.CurrentFloorPart).toBe(slope)
			expect(query.FloorNormal.X).toBeCloseTo(-0.5, 3) -- -sin(30)
			expect(query.FloorNormal.Y).toBeCloseTo(math.cos(math.rad(30)), 3)
		end)

		it("should not be grounded on a slope steeper than the max slope angle", function()
			spawnSlab(Vector3.new(0, -1.4, 0), 70)

			query:UpdateState()

			expect(query:IsGrounded()).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
			expect(query.FloorNormal == Vector3.zero).toBe(true)
		end)

		it("should ignore parts that belong to the character model", function()
			local accessory = world:SpawnPart({
				Size = Vector3.new(4, 1, 4),
				Position = Vector3.new(0, -1.8, 0), -- top at -1.3, would be in range
			})
			accessory.Parent = character

			query:UpdateState()

			expect(query:IsGrounded()).toBe(false)
		end)

		it("should clear grounded state when the floor goes away", function()
			local floor = spawnFloor(-1.3)
			query:UpdateState()
			expect(query:IsGrounded()).toBe(true)

			floor.Position = Vector3.new(0, -100, 0)
			query:UpdateState()

			expect(query:IsGrounded()).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
			expect(query.FloorNormal == Vector3.zero).toBe(true)
			expect(query.MovingPlatformDelta == CFrame.identity).toBe(true)
		end)
	end)

	describe("MovingPlatformDelta", function()
		it("should be identity on the first frame of landing", function()
			spawnFloor(-1.3)

			query:UpdateState()

			expect(query.MovingPlatformDelta == CFrame.identity).toBe(true)
		end)

		it("should be identity while standing on a stationary floor", function()
			spawnFloor(-1.3)

			query:UpdateState()
			query:UpdateState()

			expect(query.MovingPlatformDelta.Position.Magnitude).toBeCloseTo(0, 3)
		end)

		it("should report the platform's movement between frames", function()
			local platform = spawnFloor(-1.3)
			query:UpdateState()

			platform.Position += Vector3.new(5, 0, 0)
			query:UpdateState()

			expectVector(query.MovingPlatformDelta.Position, Vector3.new(5, 0, 0))
		end)

		it("should reset to identity when switching to a different platform", function()
			local platformA = spawnFloor(-1.3)
			query:UpdateState()
			expect(query.CurrentFloorPart).toBe(platformA)

			-- Move A away and put B in range
			platformA.Position = Vector3.new(0, -100, 0)
			local platformB = spawnFloor(-1.4)
			query:UpdateState()

			expect(query.CurrentFloorPart).toBe(platformB)
			expect(query.MovingPlatformDelta == CFrame.identity).toBe(true)
		end)

		it("should not carry a stale delta across an airborne gap", function()
			local platform = spawnFloor(-1.3)
			query:UpdateState()

			-- Leave the ground, move the platform, then land again
			local originalPosition = platform.Position
			platform.Position = Vector3.new(0, -100, 0)
			query:UpdateState()
			platform.Position = originalPosition + Vector3.new(5, 0, 0)
			query:UpdateState()

			expect(query:IsGrounded()).toBe(true)
			expect(query.MovingPlatformDelta == CFrame.identity).toBe(true)
		end)
	end)

	describe("CheckWallContact", function()
		it("should return false when nothing is nearby", function()
			expect(query:CheckWallContact(Direction.Right)).toBe(false)
		end)

		it("should detect a wall on the right", function()
			spawnWall(1.3)

			expect(query:CheckWallContact(Direction.Right)).toBe(true)
		end)

		it("should detect a wall on the left", function()
			spawnWall(-1.3)

			expect(query:CheckWallContact(Direction.Left)).toBe(true)
		end)

		it("should only check the requested direction", function()
			spawnWall(1.3)

			expect(query:CheckWallContact(Direction.Left)).toBe(false)
		end)

		it("should return false when the wall is beyond check distance", function()
			spawnWall(3)

			expect(query:CheckWallContact(Direction.Right)).toBe(false)
		end)

		it("should return false for Direction.None", function()
			spawnWall(1.3)
			spawnWall(-1.3)

			expect(query:CheckWallContact(Direction.None)).toBe(false)
		end)

		it("should not treat a walkable slope as a wall", function()
			-- Gentle slope whose top face crosses the +X ray at x = 1.3
			spawnSlab(Vector3.new(1.3, 0, 0), 30)

			expect(query:CheckWallContact(Direction.Right)).toBe(false)
		end)

		it("should ignore parts that belong to the character model", function()
			local accessory = spawnWall(1.3)
			accessory.Parent = character

			expect(query:CheckWallContact(Direction.Right)).toBe(false)
		end)
	end)

	describe("GetSweepResolution", function()
		it("should return the default resolution for a zero delta", function()
			spawnWall(1.3)

			local resolution = query:GetSweepResolution(Vector3.zero)

			expectResolution(resolution, Vector3.zero, false, false)
		end)

		it("should pass the full delta through when nothing is in the way", function()
			local delta = Vector3.new(0, 3, 0)

			local resolution = query:GetSweepResolution(delta)

			expectResolution(resolution, delta, false, false)
		end)

		it("should pass the full delta through when the obstacle is out of reach", function()
			spawnWall(6) -- 5 studs of gap, sweeping only 1
			local delta = Vector3.new(1, 0, 0)

			local resolution = query:GetSweepResolution(delta)

			expectResolution(resolution, delta, false, false)
		end)

		it("should stop short of a wall by the skin width and flag hitWall", function()
			spawnWall(2) -- hitbox face at x = 1 -> 1 stud of gap
			local delta = Vector3.new(3, 0, 0)

			local resolution = query:GetSweepResolution(delta)

			-- 1.0 gap - 0.1 skin = 0.9
			expectResolution(resolution, Vector3.new(0.9, 0, 0), false, true)
		end)

		it("should stop short of a floor by the skin width and flag hitFloor", function()
			spawnFloor(-2) -- hitbox bottom at y = -1 -> 1 stud of gap
			local delta = Vector3.new(0, -3, 0)

			local resolution = query:GetSweepResolution(delta)

			expectResolution(resolution, Vector3.new(0, -0.9, 0), true, false)
		end)

		it("should not move when the gap is smaller than the skin width", function()
			spawnWall(1.05) -- 0.05 gap < 0.1 skin
			local delta = Vector3.new(1, 0, 0)

			local resolution = query:GetSweepResolution(delta)

			expectResolution(resolution, Vector3.zero, false, true)
		end)

		it("should clamp along the direction of travel for diagonal deltas", function()
			spawnWall(2)
			local delta = Vector3.new(3, 0, 3)

			local resolution = query:GetSweepResolution(delta)

			local safeDelta = resolution.safeDelta
			expect(safeDelta.Magnitude).toBeLessThan(delta.Magnitude)
			expect(safeDelta.Unit.X).toBeCloseTo(delta.Unit.X, 3)
			expect(safeDelta.Unit.Z).toBeCloseTo(delta.Unit.Z, 3)
			expect(resolution.hitWall).toBe(true)
		end)

		it("should ignore parts that belong to the character model", function()
			local accessory = spawnWall(2)
			accessory.Parent = character
			local delta = Vector3.new(3, 0, 0)

			local resolution = query:GetSweepResolution(delta)

			expectResolution(resolution, delta, false, false)
		end)
	end)

	describe("Destroy", function()
		it("should clear floor state", function()
			spawnFloor(-1.3)
			query:UpdateState()
			expect(query.CurrentFloorPart).toBeDefined()

			query:Destroy()

			expect(query.CurrentFloorPart).toBeNil()
		end)

		it("should clear the raycast filter", function()
			query:Destroy()

			expect(#query._raycastParams.FilterDescendantsInstances).toBe(0)
		end)

		it("should be safe to call twice", function()
			query:Destroy()

			expect(function()
				query:Destroy()
			end).never.toThrow()
		end)
	end)
end)