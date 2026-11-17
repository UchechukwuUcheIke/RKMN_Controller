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
local LedgeGuard = require(CollisionQueryFolder.LedgeGuard)
local GroundProbe = require(CollisionQueryFolder.GroundProbe)
local SlopeClassifier = require(CollisionQueryFolder.SlopeClassifier)
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local SurfaceHits = require(RKMNControllerFolder.SurfaceHits)
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)

local tolerances = table.freeze({
	GroundCheckDistance = 0.5,
	WallCheckDistance = 0.5,
	SkinWidth = 0.1,
	MaxSlopeAngle = 45,
})

describe("LedgeGuard", function()
	local world
	local character
	local groundProbe
	local guard

	local function makeBody(model)
		local body = CollisionBody.new(model)
		body._footSize = Vector3.new(0.2, 0.1, 0.2)
		return body
	end

	-- Flat floor spanning x in [-10, 10], top face at `topY`
	local function spawnFloor(topY)
		return world:SpawnPart({
			Size = Vector3.new(20, 1, 20),
			Position = Vector3.new(0, topY - 0.5, 0),
		})
	end

	local function makeResolution(safeDelta)
		local castRecord = DiagnosticCastRecord.fromBlockcast(false, CFrame.new(), Vector3.one, safeDelta)
		return SweepResolution.new(castRecord, safeDelta, SurfaceHits.new())
	end

	beforeEach(function()
		world = MockWorld.new()
		character = world:SpawnCharacter()

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { character }

		groundProbe = GroundProbe.new(
			world,
			makeBody(character),
			tolerances,
			SlopeClassifier.new(tolerances.MaxSlopeAngle),
			raycastParams
		)
		guard = LedgeGuard.new(groundProbe)
	end)

	afterEach(function()
		if world then
			world:Destroy()
		end
	end)

	describe("Apply", function()
		it("should return the resolution unchanged while disabled", function()
			spawnFloor(-1.3)
			groundProbe:Update()
			local resolution = makeResolution(Vector3.new(15, 0, 0))

			expect(guard:Apply(resolution)).toBe(resolution)
		end)

		it("should return the resolution unchanged while enabled but not grounded", function()
			guard:SetEnabled(true)
			local resolution = makeResolution(Vector3.new(15, 0, 0))

			expect(guard:Apply(resolution)).toBe(resolution)
		end)

		it("should return the resolution unchanged when ground continues under the move", function()
			spawnFloor(-1.3)
			groundProbe:Update()
			guard:SetEnabled(true)
			local resolution = makeResolution(Vector3.new(3, 0, 0))

			expect(guard:Apply(resolution)).toBe(resolution)
		end)

		it("should return the resolution unchanged for a purely vertical move", function()
			spawnFloor(-1.3)
			groundProbe:Update()
			guard:SetEnabled(true)
			local resolution = makeResolution(Vector3.new(0, 3, 0))

			expect(guard:Apply(resolution)).toBe(resolution)
		end)

		it("should clamp the horizontal delta and flag HitLedge when the move leaves the ground", function()
			spawnFloor(-1.3)
			groundProbe:Update()
			guard:SetEnabled(true)

			local result = guard:Apply(makeResolution(Vector3.new(15, 2, 0)))

			expect(result.SurfaceHits.HitLedge).toBe(true)
			expect(result.SafeDelta.X).toBeGreaterThan(0)
			expect(result.SafeDelta.X).toBeLessThan(10)
			expect(result.SafeDelta.Y).toBe(2)
		end)

		it("should keep the other surface hits when flagging HitLedge", function()
			spawnFloor(-1.3)
			groundProbe:Update()
			guard:SetEnabled(true)
			local castRecord = DiagnosticCastRecord.fromBlockcast(true, CFrame.new(), Vector3.one, Vector3.new(15, 0, 0))
			local resolution = SweepResolution.new(castRecord, Vector3.new(15, 0, 0), SurfaceHits.new(false, true, false))

			local result = guard:Apply(resolution)

			expect(result.SurfaceHits.HitWall).toBe(true)
			expect(result.SurfaceHits.HitLedge).toBe(true)
		end)
	end)

	describe("SetEnabled", function()
		it("should stop clamping once disabled again", function()
			spawnFloor(-1.3)
			groundProbe:Update()
			guard:SetEnabled(true)
			guard:SetEnabled(false)
			local resolution = makeResolution(Vector3.new(15, 0, 0))

			expect(guard:Apply(resolution)).toBe(resolution)
		end)
	end)
end)
