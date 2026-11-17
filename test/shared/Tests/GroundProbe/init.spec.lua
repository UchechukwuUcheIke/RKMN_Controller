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
local GroundProbe = require(CollisionQueryFolder.GroundProbe)
local SlopeClassifier = require(CollisionQueryFolder.SlopeClassifier)
local CollisionBody = require(RKMNControllerFolder.CollisionBody)

local function makeBody(character)
	local body = CollisionBody.new(character)

	-- Narrow foot at the bottom of the body, so slopes under it do not overlap the foot box
	body._footSize = Vector3.new(0.2, 0.1, 0.2)

	return body
end

local tolerances = table.freeze({
	GroundCheckDistance = 0.5,
	WallCheckDistance = 0.5,
	SkinWidth = 0.1,
	MaxSlopeAngle = 45,
})

describe("GroundProbe", function()
	local world
	local character
	local probe

	-- Flat floor whose top face is at `topY`
	local function spawnFloor(topY)
		return world:SpawnPart({
			Size = Vector3.new(20, 1, 20),
			Position = Vector3.new(0, topY - 0.5, 0),
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

	beforeEach(function()
		world = MockWorld.new()
		character = world:SpawnCharacter()

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { character }

		probe = GroundProbe.new(
			world,
			makeBody(character),
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

	describe("new", function()
		it("should start in a not-grounded state", function()
			expect(probe:IsGrounded()).toBe(false)
			expect(probe.CurrentFloorPart).toBeNil()
			expect(probe.FloorNormal == Vector3.zero).toBe(true)
		end)
	end)

	describe("Update", function()
		it("should not be grounded when there is no floor", function()
			probe:Update()

			expect(probe:IsGrounded()).toBe(false)
			expect(probe.CurrentFloorPart).toBeNil()
			expect(probe.FloorNormal == Vector3.zero).toBe(true)
		end)

		it("should be grounded on a floor within check distance", function()
			local floor = spawnFloor(-1.3)

			probe:Update()

			expect(probe:IsGrounded()).toBe(true)
			expect(probe.CurrentFloorPart).toBe(floor)
			expectVector(probe.FloorNormal, Vector3.yAxis)
		end)

		it("should include the skin width in the ground check distance", function()
			-- Gap of 0.55: beyond GroundCheckDistance (0.5) but inside GroundCheckDistance + SkinWidth (0.6)
			spawnFloor(-1.55)

			probe:Update()

			expect(probe:IsGrounded()).toBe(true)
		end)

		it("should not be grounded when the floor is beyond check distance plus skin width", function()
			-- Gap of 0.7 > 0.6
			spawnFloor(-1.7)

			probe:Update()

			expect(probe:IsGrounded()).toBe(false)
			expect(probe.CurrentFloorPart).toBeNil()
		end)

		it("should be grounded on a slope below the max slope angle", function()
			local slope = spawnSlab(Vector3.new(0, -1.4, 0), 30)

			probe:Update()

			expect(probe:IsGrounded()).toBe(true)
			expect(probe.CurrentFloorPart).toBe(slope)
			expect(probe.FloorNormal.X).toBeCloseTo(-math.sin(math.rad(30)), 3)
			expect(probe.FloorNormal.Y).toBeCloseTo(math.cos(math.rad(30)), 3)
		end)

		it("should not be grounded on a slope steeper than the max slope angle", function()
			spawnSlab(Vector3.new(0, -1.4, 0), 70)

			probe:Update()

			expect(probe:IsGrounded()).toBe(false)
			expect(probe.CurrentFloorPart).toBeNil()
			expect(probe.FloorNormal == Vector3.zero).toBe(true)
		end)

		it("should ignore parts that belong to the character model", function()
			local accessory = world:SpawnPart({
				Size = Vector3.new(4, 1, 4),
				Position = Vector3.new(0, -1.8, 0), -- top at -1.3, would be in range
			})
			accessory.Parent = character

			probe:Update()

			expect(probe:IsGrounded()).toBe(false)
		end)

		it("should clear grounded state when the floor goes away", function()
			local floor = spawnFloor(-1.3)
			probe:Update()
			expect(probe:IsGrounded()).toBe(true)

			floor.Position = Vector3.new(0, -100, 0)
			probe:Update()

			expect(probe:IsGrounded()).toBe(false)
			expect(probe.FloorNormal == Vector3.zero).toBe(true)
			-- NOTE: this currently fails: leaving the ground doesn't reset CurrentFloorPart
			expect(probe.CurrentFloorPart).toBeNil()
		end)

		it("should track a new floor part when the floor changes", function()
			local platformA = spawnFloor(-1.3)
			probe:Update()
			expect(probe.CurrentFloorPart).toBe(platformA)

			platformA.Position = Vector3.new(0, -100, 0)
			local platformB = spawnFloor(-1.4)
			probe:Update()

			expect(probe:IsGrounded()).toBe(true)
			expect(probe.CurrentFloorPart).toBe(platformB)
		end)

		it("should update the floor normal when moving from a flat floor to a slope", function()
			local floor = spawnFloor(-1.3)
			probe:Update()
			expectVector(probe.FloorNormal, Vector3.yAxis)

			floor.Position = Vector3.new(0, -100, 0)
			spawnSlab(Vector3.new(0, -1.4, 0), 30)
			probe:Update()

			expect(probe.FloorNormal.Y).toBeCloseTo(math.cos(math.rad(30)), 3)
		end)
	end)

	describe("HasWalkableGroundAt", function()
		it("should find ground directly below with a zero offset", function()
			spawnFloor(-1.3)

			expect(probe:HasWalkableGroundAt(Vector3.zero)).toBe(true)
		end)

		it("should not find ground past the edge of the floor", function()
			spawnFloor(-1.3) -- spans x in [-10, 10]

			expect(probe:HasWalkableGroundAt(Vector3.new(15, 0, 0))).toBe(false)
		end)

		it("should not find ground on a too-steep slope", function()
			spawnSlab(Vector3.new(0, -1.4, 0), 70)

			expect(probe:HasWalkableGroundAt(Vector3.zero)).toBe(false)
		end)

		it("should not change the probe's grounded state", function()
			spawnFloor(-1.3)

			probe:HasWalkableGroundAt(Vector3.zero)

			expect(probe:IsGrounded()).toBe(false)
			expect(probe.CurrentFloorPart).toBeNil()
		end)
	end)

	describe("Reset", function()
		it("should clear the current floor part", function()
			spawnFloor(-1.3)
			probe:Update()
			expect(probe.CurrentFloorPart).toBeDefined()

			probe:Reset()

			expect(probe.CurrentFloorPart).toBeNil()
		end)
	end)
end)
