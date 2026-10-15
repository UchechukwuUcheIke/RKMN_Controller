--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local RKMNCameraFolder = ReplicatedStorage.RKMNCamera
local CameraTargetSolver = require(RKMNCameraFolder.CameraTargetSolver)
local CameraZone = require(RKMNCameraFolder.Data.CameraZone)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local FOV = 60
local WIDESCREEN = 16 / 9
local OFFSET = Vector3.new(0, 0, 30)
local HALF_HEIGHT = 30 * math.tan(math.rad(FOV) / 2)
local HALF_WIDTH = HALF_HEIGHT * WIDESCREEN

local function view(aspect: number)
	return { VerticalFieldOfView = FOV, Aspect = aspect }
end

local DT = 1 / 60

local function solve(playerCFrame, zone, viewParams, state, isGrounded)
	return CameraTargetSolver.Solve(playerCFrame, zone, viewParams, state, isGrounded or false, DT)
end

local function playerAt(x: number, y: number, z: number?)
	return CFrame.new(x, y, z or 0)
end

-- 200 wide, 100 tall, centered on the origin
local function makeWideRail()
	return CameraZone.createRail("Wide", Vector3.zero, Vector3.new(200, 100, 10), OFFSET)
end

describe("CameraTargetSolver", function()
	describe("no zone", function()
		it("follows the player with the fallback offset", function()
			local result = solve(playerAt(5, 6, 7), nil, view(WIDESCREEN))
			expect(result.Position).toBe(Vector3.new(5, 10, 37))
		end)
	end)

	describe("locked zone", function()
		it("returns the fixed viewport regardless of the player", function()
			local focus = CFrame.new(1, 2, 3) * CFrame.Angles(0, math.rad(45), 0)
			local zone = CameraZone.createLocked("Boss", Vector3.zero, Vector3.new(50, 50, 50), focus)
			local result = solve(playerAt(40, 0), zone, view(WIDESCREEN))
			expect(result).toBe(focus)
		end)
	end)

	describe("rail zone", function()
		it("follows the player plus the offset when well inside the zone", function()
			local result = solve(playerAt(10, 5, -4), makeWideRail(), view(WIDESCREEN))
			expect(result.Position).toBe(Vector3.new(10, 5, 26))
		end)

		it("uses an identity rotation", function()
			local result = solve(playerAt(0, 0), makeWideRail(), view(WIDESCREEN))
			expect(result.Rotation).toBe(CFrame.new())
		end)

		it("keeps the view inside the right edge", function()
			local result = solve(playerAt(500, 0), makeWideRail(), view(WIDESCREEN))
			expect(result.Position.X).toBeCloseTo(100 - HALF_WIDTH, 5)
		end)

		it("keeps the view inside the left edge", function()
			local result = solve(playerAt(-500, 0), makeWideRail(), view(WIDESCREEN))
			expect(result.Position.X).toBeCloseTo(-100 + HALF_WIDTH, 5)
		end)

		it("keeps the view inside the top edge", function()
			local result = solve(playerAt(0, 500), makeWideRail(), view(WIDESCREEN))
			expect(result.Position.Y).toBeCloseTo(50 - HALF_HEIGHT, 5)
		end)

		it("keeps the view inside the bottom edge", function()
			local result = solve(playerAt(0, -500), makeWideRail(), view(WIDESCREEN))
			expect(result.Position.Y).toBeCloseTo(-50 + HALF_HEIGHT, 5)
		end)

		it("does not clamp Z", function()
			local result = solve(playerAt(0, 0, 100), makeWideRail(), view(WIDESCREEN))
			expect(result.Position.Z).toBe(130)
		end)

		it("clamps a narrower screen with its true aspect", function()
			local result = solve(playerAt(500, 0), makeWideRail(), view(1))
			expect(result.Position.X).toBeCloseTo(100 - HALF_HEIGHT, 5)
		end)

		it("clamps an ultrawide screen as if it were 16:9", function()
			local ultrawide = solve(playerAt(500, 0), makeWideRail(), view(32 / 9))
			local widescreen = solve(playerAt(500, 0), makeWideRail(), view(WIDESCREEN))
			expect(ultrawide.Position.X).toBeCloseTo(widescreen.Position.X, 5)
		end)

		it("centers on the zone when it is narrower than the view", function()
			local narrow = CameraZone.createRail("Narrow", Vector3.new(40, 0, 0), Vector3.new(20, 100, 10), OFFSET)
			local result = solve(playerAt(500, 0), narrow, view(WIDESCREEN))
			expect(result.Position.X).toBe(40)
		end)

		it("centers on the zone when it is shorter than the view", function()
			local short = CameraZone.createRail("Short", Vector3.new(0, 20, 0), Vector3.new(200, 10, 10), OFFSET)
			local result = solve(playerAt(0, 500), short, view(WIDESCREEN))
			expect(result.Position.Y).toBe(20)
		end)

		it("pins the view flush against an edge when the zone is exactly the view size", function()
			local exact = CameraZone.createRail("Exact", Vector3.zero, Vector3.new(HALF_WIDTH * 2, HALF_HEIGHT * 2, 10), OFFSET)
			local result = solve(playerAt(500, 500), exact, view(WIDESCREEN))
			expect(result.Position.X).toBeCloseTo(0, 5)
			expect(result.Position.Y).toBeCloseTo(0, 5)
		end)

		it("clamps a deeper offset with a wider view", function()
			local deep = CameraZone.createRail("Deep", Vector3.zero, Vector3.new(200, 100, 10), Vector3.new(0, 0, 60))
			local result = solve(playerAt(500, 0), deep, view(WIDESCREEN))
			expect(result.Position.X).toBeCloseTo(100 - HALF_WIDTH * 2, 5)
		end)
	end)

	describe("vertical follow", function()
		local function makeRail(options)
			return CameraZone.createRail("Vertical", Vector3.zero, Vector3.new(200, 1000, 10), OFFSET, options)
		end

		it("seeds the state from the player when there is none", function()
			local _, state = solve(playerAt(0, 12), makeRail(), view(WIDESCREEN))
			expect(state.FocusY).toBeCloseTo(12, 5)
		end)

		it("tracking follows the player exactly", function()
			local zone = makeRail({ VerticalFollow = "Tracking" })
			local result = solve(playerAt(0, 40), zone, view(WIDESCREEN), { FocusY = 0 })
			expect(result.Position.Y).toBeCloseTo(40, 5)
		end)

		it("deadzone holds the focus while the player stays inside it", function()
			local zone = makeRail({ VerticalFollow = "Deadzone", DeadzoneFraction = 0.5 })
			local result = solve(playerAt(0, HALF_HEIGHT * 0.25), zone, view(WIDESCREEN), { FocusY = 0 })
			expect(result.Position.Y).toBeCloseTo(0, 5)
		end)

		it("deadzone pushes the focus when the player leaves it", function()
			local zone = makeRail({ VerticalFollow = "Deadzone", DeadzoneFraction = 0.5 })
			local result = solve(playerAt(0, HALF_HEIGHT), zone, view(WIDESCREEN), { FocusY = 0 })
			expect(result.Position.Y).toBeCloseTo(HALF_HEIGHT * 0.5, 5)
		end)

		it("deadzone eases toward a grounded player at the scroll speed", function()
			local zone = makeRail({ VerticalFollow = "Deadzone", DeadzoneFraction = 0.5, GroundedScrollSpeed = 6 })
			local result = solve(playerAt(0, HALF_HEIGHT * 0.25), zone, view(WIDESCREEN), { FocusY = 0 }, true)
			expect(result.Position.Y).toBeCloseTo(6 * DT, 5)
		end)

		it("locked pins the focus to the zone center minus the offset", function()
			local zone = CameraZone.createRail("Pinned", Vector3.new(0, 20, 0), Vector3.new(200, 1000, 10), Vector3.new(0, 4, 30), {
				VerticalFollow = "Locked",
			})
			local result = solve(playerAt(0, 300), zone, view(WIDESCREEN), { FocusY = 0 })
			expect(result.Position.Y).toBeCloseTo(20, 5)
		end)
	end)

	describe("createRail", function()
		it("rejects an offset that is not in front of the player", function()
			expect(function()
				CameraZone.createRail("Bad", Vector3.zero, Vector3.new(10, 10, 10), Vector3.new(0, 0, -30))
			end).toThrow()
		end)

		it("rejects a zero Z offset", function()
			expect(function()
				CameraZone.createRail("Bad", Vector3.zero, Vector3.new(10, 10, 10), Vector3.new(0, 4, 0))
			end).toThrow()
		end)
	end)
end)
