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
local CollisionQueryFolder = RKMNControllerFolder.CollisionQuery
local SweepResolver = require(CollisionQueryFolder.SweepResolver)
local SlopeClassifier = require(CollisionQueryFolder.SlopeClassifier)
local CollisionBody = require(RKMNControllerFolder.CollisionBody)

local tolerances = table.freeze({
	GroundCheckDistance = 0.5,
	WallCheckDistance = 0.5,
	SkinWidth = 0.1,
	MaxSlopeAngle = 45,
})

describe("SweepResolver", function()
	local world
	local character
	local resolver

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
		expectVector(resolution.SafeDelta, expectedDelta)
		expect(resolution.SurfaceHits.HitFloor).toBe(expectedHitFloor)
		expect(resolution.SurfaceHits.HitWall).toBe(expectedHitWall)
	end

	beforeEach(function()
		world = MockWorld.new()
		character = world:SpawnCharacter()

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { character }

		resolver = SweepResolver.new(
			world,
			CollisionBody.new(character),
			tolerances,
			SlopeClassifier.new(tolerances.MaxSlopeAngle),
			raycastParams
		)
	end)

	afterEach(function()
		if world then
			world:Destroy()
		end
	end)

	describe("Resolve", function()
		it("should return the default resolution for a zero delta", function()
			spawnWall(1.3)

			local resolution = resolver:Resolve(Vector3.zero)

			expectResolution(resolution, Vector3.zero, false, false)
		end)

		it("should pass the full delta through when nothing is in the way", function()
			local delta = Vector3.new(0, 3, 0)

			local resolution = resolver:Resolve(delta)

			expectResolution(resolution, delta, false, false)
		end)

		it("should pass the full delta through when the obstacle is out of reach", function()
			spawnWall(6) -- 5 studs of gap, sweeping only 1
			local delta = Vector3.new(1, 0, 0)

			local resolution = resolver:Resolve(delta)

			expectResolution(resolution, delta, false, false)
		end)

		it("should stop short of a wall by the skin width and flag HitWall", function()
			spawnWall(2) -- hitbox face at x = 1 -> 1 stud of gap
			local delta = Vector3.new(3, 0, 0)

			local resolution = resolver:Resolve(delta)

			-- 1.0 gap - 0.1 skin = 0.9
			expectResolution(resolution, Vector3.new(0.9, 0, 0), false, true)
		end)

		it("should stop short of a wall on the left side", function()
			spawnWall(-2)
			local delta = Vector3.new(-3, 0, 0)

			local resolution = resolver:Resolve(delta)

			expectResolution(resolution, Vector3.new(-0.9, 0, 0), false, true)
		end)

		it("should stop short of a floor by the skin width and flag HitFloor", function()
			spawnFloor(-2) -- hitbox bottom at y = -1 -> 1 stud of gap
			local delta = Vector3.new(0, -3, 0)

			local resolution = resolver:Resolve(delta)

			expectResolution(resolution, Vector3.new(0, -0.9, 0), true, false)
		end)

		it("should flag HitCeiling (not HitWall or HitFloor) when sweeping up into a ceiling", function()
			-- Ceiling underside at y = 2, hitbox top at y = 1 -> 1 stud of gap
			world:SpawnPart({
				Size = Vector3.new(20, 1, 20),
				Position = Vector3.new(0, 2.5, 0),
			})
			local delta = Vector3.new(0, 3, 0)

			local resolution = resolver:Resolve(delta)

			expectVector(resolution.SafeDelta, Vector3.new(0, 0.9, 0))
			expect(resolution.SurfaceHits.HitCeiling).toBe(true)
			expect(resolution.SurfaceHits.HitFloor).toBe(false)
			expect(resolution.SurfaceHits.HitWall).toBe(false)
		end)

		it("should flag HitFloor when sweeping down onto a walkable slope", function()
			spawnSlab(Vector3.new(0, -2, 0), 30)
			local delta = Vector3.new(0, -3, 0)

			local resolution = resolver:Resolve(delta)

			expect(resolution.SurfaceHits.HitFloor).toBe(true)
			expect(resolution.SurfaceHits.HitWall).toBe(false)
			expect(resolution.SafeDelta.Y).toBeLessThan(0)
			expect(resolution.SafeDelta.Magnitude).toBeLessThan(delta.Magnitude)
		end)

		it("should flag HitWall when sweeping down onto a too-steep slope", function()
			spawnSlab(Vector3.new(0, -2, 0), 70)
			local delta = Vector3.new(0, -3, 0)

			local resolution = resolver:Resolve(delta)

			expect(resolution.SurfaceHits.HitFloor).toBe(false)
			expect(resolution.SurfaceHits.HitWall).toBe(true)
		end)

		it("should not move when the gap is smaller than the skin width", function()
			spawnWall(1.05) -- 0.05 gap < 0.1 skin
			local delta = Vector3.new(1, 0, 0)

			local resolution = resolver:Resolve(delta)

			expectResolution(resolution, Vector3.zero, false, true)
		end)

		it("should clamp along the direction of travel for diagonal deltas", function()
			spawnWall(2)
			local delta = Vector3.new(3, 0, 3)

			local resolution = resolver:Resolve(delta)

			local safeDelta = resolution.SafeDelta
			expect(safeDelta.Magnitude).toBeLessThan(delta.Magnitude)
			expect(safeDelta.Unit.X).toBeCloseTo(delta.Unit.X, 3)
			expect(safeDelta.Unit.Z).toBeCloseTo(delta.Unit.Z, 3)
			expect(resolution.SurfaceHits.HitWall).toBe(true)
		end)

		it("should ignore parts that belong to the character model", function()
			local accessory = spawnWall(2)
			accessory.Parent = character
			local delta = Vector3.new(3, 0, 0)

			local resolution = resolver:Resolve(delta)

			expectResolution(resolution, delta, false, false)
		end)

		it("should never flag HitLedge", function()
			local resolution = resolver:Resolve(Vector3.new(3, 0, 0))

			expect(resolution.SurfaceHits.HitLedge).toBe(false)
		end)
	end)
end)
