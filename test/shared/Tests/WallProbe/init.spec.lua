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
local WallProbe = require(CollisionQueryFolder.WallProbe)
local SlopeClassifier = require(CollisionQueryFolder.SlopeClassifier)
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local Direction = require(ReplicatedStorage.Data.Direction)

local tolerances = table.freeze({
	GroundCheckDistance = 0.5,
	WallCheckDistance = 0.5,
	SkinWidth = 0.1,
	MaxSlopeAngle = 45,
})

describe("WallProbe", function()
	local world
	local character
	local probe

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

	-- CheckContact returns a DiagnosticCastRecord, not a boolean;
	-- the contact result lives in its Success field.
	local function hasContact(castRecord)
		return castRecord.Success
	end

	beforeEach(function()
		world = MockWorld.new()
		character = world:SpawnCharacter()

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { character }

		probe = WallProbe.new(
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

	describe("CheckContact", function()
		it("should return a cast record with no contact when nothing is nearby", function()
			local record = probe:CheckContact(Direction.Right)

			expect(record).toBeDefined()
			expect(hasContact(record)).toBe(false)
		end)

		it("should detect a wall on the right", function()
			spawnWall(1.3)

			expect(hasContact(probe:CheckContact(Direction.Right))).toBe(true)
		end)

		it("should detect a wall on the left", function()
			spawnWall(-1.3)

			expect(hasContact(probe:CheckContact(Direction.Left))).toBe(true)
		end)

		it("should only check the requested direction", function()
			spawnWall(1.3)

			expect(hasContact(probe:CheckContact(Direction.Left))).toBe(false)
		end)

		it("should return no contact when the wall is beyond check distance", function()
			spawnWall(3)

			expect(hasContact(probe:CheckContact(Direction.Right))).toBe(false)
		end)

		it("should include the skin width in the wall check distance", function()
			-- Gap of 0.55 from the ray origin: beyond WallCheckDistance (0.5), inside +SkinWidth (0.6)
			spawnWall(1.55)

			expect(hasContact(probe:CheckContact(Direction.Right))).toBe(true)
		end)

		it("should return no contact for Direction.None", function()
			spawnWall(1.3)
			spawnWall(-1.3)

			expect(hasContact(probe:CheckContact(Direction.None))).toBe(false)
		end)

		it("should not treat a walkable slope as a wall", function()
			-- Gentle slope whose top face crosses the +X ray at x = 1.3
			spawnSlab(Vector3.new(1.3, 0, 0), 30)

			expect(hasContact(probe:CheckContact(Direction.Right))).toBe(false)
		end)

		it("should treat a too-steep slope as a wall", function()
			spawnSlab(Vector3.new(1.3, 0, 0), 70)

			expect(hasContact(probe:CheckContact(Direction.Right))).toBe(true)
		end)

		it("should ignore parts that belong to the character model", function()
			local accessory = spawnWall(1.3)
			accessory.Parent = character

			expect(hasContact(probe:CheckContact(Direction.Right))).toBe(false)
		end)
	end)
end)
