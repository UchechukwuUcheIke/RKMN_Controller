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

	-- CheckWallContact returns a DiagnosticCastRecord, not a boolean;
	-- the contact result lives in its Success field.
	local function hasContact(castRecord)
		return castRecord.Success
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
			expect(query.IsGrounded).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
			expect(query.FloorNormal == Vector3.zero).toBe(true)
		end)

		it("should precompute the max slope dot from the max slope angle", function()
			expect(query._maxSlopeDot).toBeCloseTo(math.cos(math.rad(45)), 5)
		end)

		it("should exclude the character from the raycast filter", function()
			local params = query._raycastParams

			expect(params.FilterType).toBe(Enum.RaycastFilterType.Exclude)
			expect(table.find(params.FilterDescendantsInstances, character)).toBeDefined()
		end)

		it("should throw when the character has no PrimaryPart", function()
			character.PrimaryPart = nil

			expect(function()
				CollisionQuery.new(world, character, constants)
			end).toThrow("PrimaryPart")
		end)
	end)

	describe("UpdateState", function()
		it("should not be grounded when there is no floor", function()
			query:UpdateState()

			expect(query.IsGrounded).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
			expect(query.FloorNormal == Vector3.zero).toBe(true)
		end)

		it("should be grounded on a floor within check distance", function()
			local floor = spawnFloor(-1.3)

			query:UpdateState()

			expect(query.IsGrounded).toBe(true)
			expect(query.CurrentFloorPart).toBe(floor)
			expectVector(query.FloorNormal, Vector3.yAxis)
		end)

		it("should include the skin width in the ground check distance", function()
			-- Gap of 0.55: beyond GroundCheckDistance (0.5) but inside GroundCheckDistance + SkinWidth (0.6)
			spawnFloor(-1.55)

			query:UpdateState()

			expect(query.IsGrounded).toBe(true)
		end)

		it("should not be grounded when the floor is beyond check distance plus skin width", function()
			-- Gap of 0.7 > 0.6
			spawnFloor(-1.7)

			query:UpdateState()

			expect(query.IsGrounded).toBe(false)
			expect(query.CurrentFloorPart).toBeNil()
		end)

		it("should be grounded on a slope below the max slope angle", function()
			local slope = spawnSlab(Vector3.new(0, -1.4, 0), 30)

			query:UpdateState()

			expect(query.IsGrounded).toBe(true)
			expect(query.CurrentFloorPart).toBe(slope)
			expect(query.FloorNormal.X).toBeCloseTo(-math.sin(math.rad(30)), 3)
			expect(query.FloorNormal.Y).toBeCloseTo(math.cos(math.rad(30)), 3)
		end)

		it("should not be grounded on a slope steeper than the max slope angle", function()
			spawnSlab(Vector3.new(0, -1.4, 0), 70)

			query:UpdateState()

			expect(query.IsGrounded).toBe(false)
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

			expect(query.IsGrounded).toBe(false)
		end)

		it("should clear grounded state when the floor goes away", function()
			local floor = spawnFloor(-1.3)
			query:UpdateState()
			expect(query.IsGrounded).toBe(true)

			floor.Position = Vector3.new(0, -100, 0)
			query:UpdateState()

			expect(query.IsGrounded).toBe(false)
			expect(query.FloorNormal == Vector3.zero).toBe(true)
			-- NOTE: this currently fails: _updateStateToNotOnGround doesn't reset CurrentFloorPart
			expect(query.CurrentFloorPart).toBeNil()
		end)

		it("should track a new floor part when the floor changes", function()
			local platformA = spawnFloor(-1.3)
			query:UpdateState()
			expect(query.CurrentFloorPart).toBe(platformA)

			platformA.Position = Vector3.new(0, -100, 0)
			local platformB = spawnFloor(-1.4)
			query:UpdateState()

			expect(query.IsGrounded).toBe(true)
			expect(query.CurrentFloorPart).toBe(platformB)
		end)

		it("should update the floor normal when moving from a flat floor to a slope", function()
			local floor = spawnFloor(-1.3)
			query:UpdateState()
			expectVector(query.FloorNormal, Vector3.yAxis)

			floor.Position = Vector3.new(0, -100, 0)
			spawnSlab(Vector3.new(0, -1.4, 0), 30)
			query:UpdateState()

			expect(query.FloorNormal.Y).toBeCloseTo(math.cos(math.rad(30)), 3)
		end)
	end)

	describe("CheckWallContact", function()
		it("should return a cast record with no contact when nothing is nearby", function()
			local record = query:CheckWallContact(Direction.Right)

			expect(record).toBeDefined()
			expect(hasContact(record)).toBe(false)
		end)

		it("should detect a wall on the right", function()
			spawnWall(1.3)

			expect(hasContact(query:CheckWallContact(Direction.Right))).toBe(true)
		end)

		it("should detect a wall on the left", function()
			spawnWall(-1.3)

			expect(hasContact(query:CheckWallContact(Direction.Left))).toBe(true)
		end)

		it("should only check the requested direction", function()
			spawnWall(1.3)

			expect(hasContact(query:CheckWallContact(Direction.Left))).toBe(false)
		end)

		it("should return no contact when the wall is beyond check distance", function()
			spawnWall(3)

			expect(hasContact(query:CheckWallContact(Direction.Right))).toBe(false)
		end)

		it("should include the skin width in the wall check distance", function()
			-- Gap of 0.55 from the ray origin: beyond WallCheckDistance (0.5), inside +SkinWidth (0.6)
			spawnWall(1.55)

			expect(hasContact(query:CheckWallContact(Direction.Right))).toBe(true)
		end)

		it("should return no contact for Direction.None", function()
			spawnWall(1.3)
			spawnWall(-1.3)

			expect(hasContact(query:CheckWallContact(Direction.None))).toBe(false)
		end)

		it("should not treat a walkable slope as a wall", function()
			-- Gentle slope whose top face crosses the +X ray at x = 1.3
			spawnSlab(Vector3.new(1.3, 0, 0), 30)

			expect(hasContact(query:CheckWallContact(Direction.Right))).toBe(false)
		end)

		it("should treat a too-steep slope as a wall", function()
			spawnSlab(Vector3.new(1.3, 0, 0), 70)

			expect(hasContact(query:CheckWallContact(Direction.Right))).toBe(true)
		end)

		it("should ignore parts that belong to the character model", function()
			local accessory = spawnWall(1.3)
			accessory.Parent = character

			expect(hasContact(query:CheckWallContact(Direction.Right))).toBe(false)
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

		it("should stop short of a wall on the left side", function()
			spawnWall(-2)
			local delta = Vector3.new(-3, 0, 0)

			local resolution = query:GetSweepResolution(delta)

			expectResolution(resolution, Vector3.new(-0.9, 0, 0), false, true)
		end)

		it("should stop short of a floor by the skin width and flag hitFloor", function()
			spawnFloor(-2) -- hitbox bottom at y = -1 -> 1 stud of gap
			local delta = Vector3.new(0, -3, 0)

			local resolution = query:GetSweepResolution(delta)

			expectResolution(resolution, Vector3.new(0, -0.9, 0), true, false)
		end)

		it("should flag hitWall (not hitFloor) when sweeping up into a ceiling", function()
			-- Ceiling underside at y = 2, hitbox top at y = 1 -> 1 stud of gap
			world:SpawnPart({
				Size = Vector3.new(20, 1, 20),
				Position = Vector3.new(0, 2.5, 0),
			})
			local delta = Vector3.new(0, 3, 0)

			local resolution = query:GetSweepResolution(delta)

			-- Ceiling normal points down, so it isn't walkable
			expectResolution(resolution, Vector3.new(0, 0.9, 0), false, true)
		end)

		it("should flag hitFloor when sweeping down onto a walkable slope", function()
			spawnSlab(Vector3.new(0, -2, 0), 30)
			local delta = Vector3.new(0, -3, 0)

			local resolution = query:GetSweepResolution(delta)

			expect(resolution.hitFloor).toBe(true)
			expect(resolution.hitWall).toBe(false)
			expect(resolution.safeDelta.Y).toBeLessThan(0)
			expect(resolution.safeDelta.Magnitude).toBeLessThan(delta.Magnitude)
		end)

		it("should flag hitWall when sweeping down onto a too-steep slope", function()
			spawnSlab(Vector3.new(0, -2, 0), 70)
			local delta = Vector3.new(0, -3, 0)

			local resolution = query:GetSweepResolution(delta)

			expect(resolution.hitFloor).toBe(false)
			expect(resolution.hitWall).toBe(true)
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