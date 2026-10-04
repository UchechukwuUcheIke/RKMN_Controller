--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DiagnosticCastRecord = require(RKMNControllerFolder.DiagnosticCastRecord)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local PRECISION = 3
local MIN_VOLUME_THICKNESS = 0.1

local function expectVector3CloseTo(actual: Vector3, expected: Vector3)
	expect(actual.X).toBeCloseTo(expected.X, PRECISION)
	expect(actual.Y).toBeCloseTo(expected.Y, PRECISION)
	expect(actual.Z).toBeCloseTo(expected.Z, PRECISION)
end

-- Verifies the invariants every fromRaycast result should satisfy, for any origin/direction.
local function expectVolumeMatchesRay(record, origin: Vector3, direction: Vector3)
	local volume = record.CastVolume
	local length = direction.Magnitude
	local halfLength = volume.Size.Z / 2

	-- Size: box at least MIN_VOLUME_THICKNESS wide/tall, whose length equals the ray length
	expect(volume.Size.X).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
	expect(volume.Size.Y).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
	expect(volume.Size.Z).toBeCloseTo(length, PRECISION)

	-- Orientation: the box's local -Z (LookVector) points along the ray
	expectVector3CloseTo(volume.CFrame.LookVector, direction.Unit)

	-- Position: the box is centered on the midpoint of the ray
	expectVector3CloseTo(volume.CFrame.Position, origin + direction / 2)

	-- The two ends of the box land exactly on the ray's start and end
	expectVector3CloseTo(volume.CFrame.Position - volume.CFrame.LookVector * halfLength, origin)
	expectVector3CloseTo(volume.CFrame.Position + volume.CFrame.LookVector * halfLength, origin + direction)
end

describe("DiagnosticCastRecord", function()
	describe("new", function()
		local castVolume = {
			Size = Vector3.new(1, 2, 3),
			CFrame = CFrame.new(4, 5, 6),
		}

		it("returns a table", function()
			local record = DiagnosticCastRecord.new(true, castVolume)
			expect(typeof(record)).toBe("table")
		end)

		it("uses DiagnosticCastRecord as its metatable", function()
			local record = DiagnosticCastRecord.new(true, castVolume)
			expect(getmetatable(record)).toBe(DiagnosticCastRecord)
		end)

		it("stores Success = true", function()
			local record = DiagnosticCastRecord.new(true, castVolume)
			expect(record.Success).toBe(true)
		end)

		it("stores Success = false", function()
			local record = DiagnosticCastRecord.new(false, castVolume)
			expect(record.Success).toBe(false)
		end)

		it("stores the cast volume as given", function()
			local record = DiagnosticCastRecord.new(true, castVolume)

			expect(record.CastVolume).toBe(castVolume)
			expect(record.CastVolume.Size).toBe(castVolume.Size)
			expect(record.CastVolume.CFrame).toBe(castVolume.CFrame)
		end)

		it("does not modify the cast volume it is given", function()
			local volume = {
				Size = Vector3.new(1, 2, 3),
				CFrame = CFrame.new(4, 5, 6),
			}
			DiagnosticCastRecord.new(true, volume)

			expect(volume.Size).toBe(Vector3.new(1, 2, 3))
			expect(volume.CFrame).toBe(CFrame.new(4, 5, 6))
		end)

		it("creates independent records", function()
			local volumeA = { Size = Vector3.new(1, 1, 1), CFrame = CFrame.new() }
			local volumeB = { Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(1, 1, 1) }

			local recordA = DiagnosticCastRecord.new(true, volumeA)
			local recordB = DiagnosticCastRecord.new(false, volumeB)

			expect(recordA).never.toBe(recordB)
			expect(recordA.Success).toBe(true)
			expect(recordB.Success).toBe(false)
			expect(recordA.CastVolume).toBe(volumeA)
			expect(recordB.CastVolume).toBe(volumeB)
		end)

		it("allows fields to be changed on one record without affecting another", function()
			local recordA = DiagnosticCastRecord.new(true, castVolume)
			local recordB = DiagnosticCastRecord.new(true, castVolume)

			recordA.Success = false

			expect(recordA.Success).toBe(false)
			expect(recordB.Success).toBe(true)
		end)
	end)

	describe("fromRaycast", function()
		it("returns a table", function()
			local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
			expect(typeof(record)).toBe("table")
		end)

		it("returns a DiagnosticCastRecord", function()
			local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
			expect(getmetatable(record)).toBe(DiagnosticCastRecord)
		end)

		it("stores Success = true", function()
			local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
			expect(record.Success).toBe(true)
		end)

		it("stores Success = false", function()
			local record = DiagnosticCastRecord.fromRaycast(false, Vector3.zero, Vector3.new(0, 0, -10))
			expect(record.Success).toBe(false)
		end)

		it("creates a cast volume with Size and CFrame", function()
			local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))

			expect(typeof(record.CastVolume)).toBe("table")
			expect(typeof(record.CastVolume.Size)).toBe("Vector3")
			expect(typeof(record.CastVolume.CFrame)).toBe("CFrame")
		end)

		describe("size", function()
			it("has a length equal to the ray length", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
				expect(record.CastVolume.Size.Z).toBeCloseTo(10, PRECISION)
			end)

			it("is at least the minimum thickness on X and Y", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))

				expect(record.CastVolume.Size.X).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
				expect(record.CastVolume.Size.Y).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
			end)

			it("uses the magnitude of the direction as its length", function()
				-- 3-4-5 triangle, so the length is exactly 5
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(3, 4, 0))
				expect(record.CastVolume.Size.Z).toBeCloseTo(5, PRECISION)
			end)

			it("does not depend on the origin", function()
				local direction = Vector3.new(0, 0, -10)
				local atZero = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, direction)
				local farAway = DiagnosticCastRecord.fromRaycast(true, Vector3.new(100, -50, 25), direction)

				expect(farAway.CastVolume.Size.Z).toBeCloseTo(atZero.CastVolume.Size.Z, PRECISION)
				expect(farAway.CastVolume.Size.X).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
				expect(farAway.CastVolume.Size.Y).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
			end)

			it("keeps the thickness above the minimum regardless of ray length", function()
				local short = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -0.5))
				local long = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -500))

				expect(short.CastVolume.Size.X).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
				expect(short.CastVolume.Size.Y).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
				expect(long.CastVolume.Size.X).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
				expect(long.CastVolume.Size.Y).toBeGreaterThanOrEqual(MIN_VOLUME_THICKNESS)
			end)

			it("scales the length with the ray length", function()
				local short = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -5))
				local long = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -50))

				expect(short.CastVolume.Size.Z).toBeCloseTo(5, PRECISION)
				expect(long.CastVolume.Size.Z).toBeCloseTo(50, PRECISION)
			end)

			it("is the same for opposite directions", function()
				local forward = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
				local backward = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, 10))

				expect(backward.CastVolume.Size.Z).toBeCloseTo(forward.CastVolume.Size.Z, PRECISION)
			end)
		end)

		describe("position", function()
			it("is centered on the midpoint of the ray", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
				expectVector3CloseTo(record.CastVolume.CFrame.Position, Vector3.new(0, 0, -5))
			end)

			it("offsets the midpoint by the origin", function()
				local origin = Vector3.new(10, 20, 30)
				local direction = Vector3.new(0, 0, -10)
				local record = DiagnosticCastRecord.fromRaycast(true, origin, direction)

				expectVector3CloseTo(record.CastVolume.CFrame.Position, Vector3.new(10, 20, 25))
			end)

			it("handles diagonal directions", function()
				local origin = Vector3.new(1, 2, 3)
				local direction = Vector3.new(4, 6, 8)
				local record = DiagnosticCastRecord.fromRaycast(true, origin, direction)

				expectVector3CloseTo(record.CastVolume.CFrame.Position, Vector3.new(3, 5, 7))
			end)
		end)

		describe("orientation", function()
			it("faces along the ray direction", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(10, 0, 0))
				expectVector3CloseTo(record.CastVolume.CFrame.LookVector, Vector3.new(1, 0, 0))
			end)

			it("faces along -Z for a -Z ray", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
				expectVector3CloseTo(record.CastVolume.CFrame.LookVector, Vector3.new(0, 0, -1))
			end)

			it("faces along +Z for a +Z ray", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, 10))
				expectVector3CloseTo(record.CastVolume.CFrame.LookVector, Vector3.new(0, 0, 1))
			end)

			it("faces along the unit direction regardless of ray length", function()
				local short = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(1, 1, 0))
				local long = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(100, 100, 0))

				expectVector3CloseTo(short.CastVolume.CFrame.LookVector, Vector3.new(1, 1, 0).Unit)
				expectVector3CloseTo(long.CastVolume.CFrame.LookVector, Vector3.new(1, 1, 0).Unit)
			end)

			it("faces straight down for a downward ray", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.new(0, 10, 0), Vector3.new(0, -10, 0))
				expectVector3CloseTo(record.CastVolume.CFrame.LookVector, Vector3.new(0, -1, 0))
			end)

			it("faces straight up for an upward ray", function()
				local record = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 10, 0))
				expectVector3CloseTo(record.CastVolume.CFrame.LookVector, Vector3.new(0, 1, 0))
			end)
		end)

		describe("volume spans the ray", function()
			it("matches a ray along -Z from the origin", function()
				local origin = Vector3.zero
				local direction = Vector3.new(0, 0, -10)
				expectVolumeMatchesRay(DiagnosticCastRecord.fromRaycast(true, origin, direction), origin, direction)
			end)

			it("matches a ray along +X from a non-zero origin", function()
				local origin = Vector3.new(5, 5, 5)
				local direction = Vector3.new(20, 0, 0)
				expectVolumeMatchesRay(DiagnosticCastRecord.fromRaycast(true, origin, direction), origin, direction)
			end)

			it("matches a diagonal ray", function()
				local origin = Vector3.new(-3, 7, 12)
				local direction = Vector3.new(4, -8, 6)
				expectVolumeMatchesRay(DiagnosticCastRecord.fromRaycast(true, origin, direction), origin, direction)
			end)

			it("matches a ray with all-negative components", function()
				local origin = Vector3.new(-50, -50, -50)
				local direction = Vector3.new(-10, -20, -30)
				expectVolumeMatchesRay(DiagnosticCastRecord.fromRaycast(true, origin, direction), origin, direction)
			end)

			it("matches a vertical ray", function()
				local origin = Vector3.new(0, 50, 0)
				local direction = Vector3.new(0, -100, 0)
				expectVolumeMatchesRay(DiagnosticCastRecord.fromRaycast(true, origin, direction), origin, direction)
			end)

			it("matches a very short ray", function()
				local origin = Vector3.new(1, 1, 1)
				local direction = Vector3.new(0, 0, -0.01)
				expectVolumeMatchesRay(DiagnosticCastRecord.fromRaycast(true, origin, direction), origin, direction)
			end)

			it("matches a very long ray", function()
				local origin = Vector3.zero
				local direction = Vector3.new(1000, 500, -2000)
				expectVolumeMatchesRay(DiagnosticCastRecord.fromRaycast(true, origin, direction), origin, direction)
			end)
		end)

		it("produces records independent of each other", function()
			local first = DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -10))
			local second = DiagnosticCastRecord.fromRaycast(false, Vector3.new(1, 1, 1), Vector3.new(5, 0, 0))

			expect(first).never.toBe(second)
			expect(first.CastVolume).never.toBe(second.CastVolume)
			expect(first.Success).toBe(true)
			expect(second.Success).toBe(false)
			expect(first.CastVolume.Size.Z).toBeCloseTo(10, PRECISION)
			expect(second.CastVolume.Size.Z).toBeCloseTo(5, PRECISION)
		end)

		it("is callable with dot syntax", function()
			expect(function()
				DiagnosticCastRecord.fromRaycast(true, Vector3.zero, Vector3.new(0, 0, -1))
			end).never.toThrow()
		end)
	end)

	describe("DiagnosticCastRecord class", function()
		it("is frozen", function()
			expect(table.isfrozen(DiagnosticCastRecord)).toBe(true)
		end)

		it("exposes the public API", function()
			expect(typeof(DiagnosticCastRecord.new)).toBe("function")
			expect(typeof(DiagnosticCastRecord.fromRaycast)).toBe("function")
		end)

		it("prevents adding new members to the class", function()
			expect(function()
				DiagnosticCastRecord.Extra = true
			end).toThrow()
		end)
	end)
end)