--!nonstrict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local WallQuery = require(ReplicatedStorage.Combat.Projectile.WallQuery)

-- Far above any level, so the real level can't be in the way.
local Y = 5000

local container
local walls

-- A wall whose near face is at x = 9, nine of the twenty studs along a cast from 0 to 20.
local function makeWall(properties)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(2, 10, 10)
	part.Position = Vector3.new(10, Y, 0)
	for key, value in properties or {} do
		part[key] = value
	end
	part.Parent = container
	CollectionService:AddTag(part, WallQuery.Tag)
	return part
end

local function castAcross()
	return walls:FindFractionToWall(Vector2.new(0, Y), Vector2.new(20, Y))
end

beforeEach(function()
	container = Instance.new("Folder")
	container.Parent = workspace
	walls = WallQuery.new(workspace)
end)

afterEach(function()
	walls:Destroy()
	container:Destroy()
end)

describe("WallQuery:FindFractionToWall", function()
	it("returns how far along the move the wall is", function()
		makeWall()

		expect(castAcross()).toBeCloseTo(0.45, 3)
	end)

	it("returns nil when the move stops short of the wall", function()
		makeWall()

		expect(walls:FindFractionToWall(Vector2.new(0, Y), Vector2.new(5, Y))).toBe(nil)
	end)

	it("returns nil for a move that goes nowhere", function()
		makeWall()

		expect(walls:FindFractionToWall(Vector2.new(0, Y), Vector2.new(0, Y))).toBe(nil)
	end)

	it("ignores parts that are not tagged as walls", function()
		local untagged = Instance.new("Part")
		untagged.Anchored = true
		untagged.Size = Vector3.new(2, 10, 10)
		untagged.Position = Vector3.new(10, Y, 0)
		untagged.Parent = container

		expect(castAcross()).toBe(nil)
	end)

	it("sees a wall tagged after the query was made", function()
		expect(castAcross()).toBe(nil)

		makeWall()

		expect(castAcross()).toBeCloseTo(0.45, 3)
	end)

	it("stops seeing a wall whose tag was removed", function()
		local wall = makeWall()
		expect(castAcross()).toBeCloseTo(0.45, 3)

		CollectionService:RemoveTag(wall, WallQuery.Tag)

		expect(castAcross()).toBe(nil)
	end)

	it("passes through walls that cannot collide", function()
		makeWall({ CanCollide = false })

		expect(castAcross()).toBe(nil)
	end)
end)

describe("WallQuery:FindPointBeforeWall", function()
	it("returns the destination when the way is clear", function()
		makeWall()

		expect(walls:FindPointBeforeWall(Vector2.new(0, Y), Vector2.new(5, Y))).toEqual(Vector2.new(5, Y))
	end)

	it("stops just in front of a wall that is in the way", function()
		makeWall()

		local reach = walls:FindPointBeforeWall(Vector2.new(0, Y), Vector2.new(20, Y))

		expect(reach.X > 8.9).toBe(true)
		expect(reach.X < 9).toBe(true)
		expect(reach.Y).toBeCloseTo(Y, 3)
	end)

	it("stays at the start when the wall is right against it", function()
		makeWall()

		local reach = walls:FindPointBeforeWall(Vector2.new(8.99, Y), Vector2.new(20, Y))

		expect(reach.X).toBeCloseTo(8.99, 3)
	end)
end)
