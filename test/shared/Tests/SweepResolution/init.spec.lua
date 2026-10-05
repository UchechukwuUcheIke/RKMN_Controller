--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local DiagnosticCastRecord = require(ReplicatedStorage.RKMNController.DiagnosticCastRecord)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local SweepResolution = require(RKMNControllerFolder.SweepResolution)
local TestUtilsFolder = ReplicatedStorage.TestUtils
local MockerUtils = require(TestUtilsFolder.MockUtils)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local jest = JestGlobals.jest

local function makeCastRecordMock(success: boolean?)
	local mock = MockerUtils.createMockClass(DiagnosticCastRecord, {
		Success = if success == nil then true else success,
		CastVolume = {
			Size = Vector3.new(0.2, 0.2, 10),
			CFrame = CFrame.new(0, 0, -5),
		},
	})

	if not mock.Mocks.Destroy then
		mock.Mocks.Destroy = jest.fn()
	end

	return mock
end

describe("SweepResolution", function()
	local castRecordMock
	local castRecord

	beforeEach(function()
		castRecordMock = makeCastRecordMock()
		castRecord = castRecordMock.Instance
	end)

	describe("new", function()
		it("stores the cast record it is given", function()
			local resolution = SweepResolution.new(castRecord)
			expect(resolution.CastRecord).toBe(castRecord)
		end)

		describe("defaults", function()
			it("defaults SafeDelta to Vector3.zero", function()
				local resolution = SweepResolution.new(castRecord)
				expect(resolution.SafeDelta).toBe(Vector3.zero)
			end)

			it("defaults HitFloor to false", function()
				local resolution = SweepResolution.new(castRecord)
				expect(resolution.HitFloor).toBe(false)
			end)

			it("defaults HitWall to false", function()
				local resolution = SweepResolution.new(castRecord)
				expect(resolution.HitWall).toBe(false)
			end)

			it("applies defaults when optional arguments are explicitly nil", function()
				local resolution = SweepResolution.new(castRecord, nil, nil, nil)

				expect(resolution.SafeDelta).toBe(Vector3.zero)
				expect(resolution.HitFloor).toBe(false)
				expect(resolution.HitWall).toBe(false)
			end)
		end)

		describe("provided values", function()
			it("stores the given SafeDelta", function()
				local resolution = SweepResolution.new(castRecord, Vector3.new(1, 2, 3))
				expect(resolution.SafeDelta).toBe(Vector3.new(1, 2, 3))
			end)

			it("stores HitFloor = true", function()
				local resolution = SweepResolution.new(castRecord, Vector3.zero, true)
				expect(resolution.HitFloor).toBe(true)
			end)

			it("stores HitWall = true", function()
				local resolution = SweepResolution.new(castRecord, Vector3.zero, false, true)
				expect(resolution.HitWall).toBe(true)
			end)

			it("stores explicit false values", function()
				local resolution = SweepResolution.new(castRecord, Vector3.zero, false, false)

				expect(resolution.HitFloor).toBe(false)
				expect(resolution.HitWall).toBe(false)
			end)

			it("stores a negative SafeDelta", function()
				local resolution = SweepResolution.new(castRecord, Vector3.new(-1, -2, -3))
				expect(resolution.SafeDelta).toBe(Vector3.new(-1, -2, -3))
			end)

			it("keeps the other defaults when only HitFloor is provided", function()
				local resolution = SweepResolution.new(castRecord, nil, true)

				expect(resolution.SafeDelta).toBe(Vector3.zero)
				expect(resolution.HitFloor).toBe(true)
				expect(resolution.HitWall).toBe(false)
			end)

			it("keeps the other defaults when only HitWall is provided", function()
				local resolution = SweepResolution.new(castRecord, nil, nil, true)

				expect(resolution.SafeDelta).toBe(Vector3.zero)
				expect(resolution.HitFloor).toBe(false)
				expect(resolution.HitWall).toBe(true)
			end)
		end)

		it("creates independent instances", function()
			local otherRecordMock = makeCastRecordMock(false)
			local first = SweepResolution.new(castRecord, Vector3.new(1, 0, 0), true, false)
			local second = SweepResolution.new(otherRecordMock.Instance, Vector3.new(0, 1, 0), false, true)

			expect(first).never.toBe(second)
			expect(first.CastRecord).toBe(castRecord)
			expect(second.CastRecord).toBe(otherRecordMock.Instance)
			expect(first.SafeDelta).toBe(Vector3.new(1, 0, 0))
			expect(second.SafeDelta).toBe(Vector3.new(0, 1, 0))
			expect(first.HitFloor).toBe(true)
			expect(second.HitFloor).toBe(false)
			expect(first.HitWall).toBe(false)
			expect(second.HitWall).toBe(true)
		end)

		it("allows fields on one instance to change without affecting another", function()
			local first = SweepResolution.new(castRecord, Vector3.zero, false, false)
			local second = SweepResolution.new(castRecord, Vector3.zero, false, false)

			first.HitFloor = true
			first.SafeDelta = Vector3.new(5, 5, 5)

			expect(second.HitFloor).toBe(false)
			expect(second.SafeDelta).toBe(Vector3.zero)
		end)
	end)

	describe("Destroy", function()
		it("destroys the cast record exactly once", function()
			local resolution = SweepResolution.new(castRecord)
			resolution:Destroy()

			expect(castRecordMock.Mocks.Destroy).toHaveBeenCalledTimes(1)
		end)

		it("calls Destroy on the record that was given to the resolution", function()
			local otherRecordMock = makeCastRecordMock()
			local resolution = SweepResolution.new(otherRecordMock.Instance)
			resolution:Destroy()

			expect(otherRecordMock.Mocks.Destroy).toHaveBeenCalledTimes(1)
			expect(castRecordMock.Mocks.Destroy).never.toHaveBeenCalled()
		end)
	end)
end)