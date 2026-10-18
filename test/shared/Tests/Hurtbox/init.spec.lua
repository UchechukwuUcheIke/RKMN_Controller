--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local Hurtbox = require(ReplicatedStorage.Combat.Hurtbox.Hurtbox)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local function makeHurtbox(overrides)
	local config = {
		OwnerId = 3,
		Team = Team.Enemy,
		Center = Vector2.new(5, 6),
		Size = Vector2.new(2, 4),
		Receive = function()
			return HitResult.Applied
		end,
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return Hurtbox.new(config)
end

describe("Hurtbox.new", function()
	it("keeps the values it is given", function()
		local hurtbox = makeHurtbox({ OwnerId = 9, Team = Team.Neutral })

		expect(hurtbox.OwnerId).toBe(9)
		expect(hurtbox.Team).toBe(Team.Neutral)
		expect(hurtbox:GetBounds().Center).toEqual(Vector2.new(5, 6))
		expect(hurtbox:GetBounds().Size).toEqual(Vector2.new(2, 4))
	end)

	it("starts enabled unless told otherwise", function()
		expect(makeHurtbox().Enabled).toBe(true)
		expect(makeHurtbox({ Enabled = false }).Enabled).toBe(false)
	end)

	it("rejects a size that is not positive on both axes", function()
		expect(function()
			makeHurtbox({ Size = Vector2.new(0, 4) })
		end).toThrow()
		expect(function()
			makeHurtbox({ Size = Vector2.new(2, -1) })
		end).toThrow()
	end)

	it("answers a hit with its Receive callback", function()
		local received
		local hurtbox = makeHurtbox({
			Receive = function(payload)
				received = payload
				return HitResult.Killed
			end,
		})

		local result = hurtbox.Receive("payload")

		expect(result).toBe(HitResult.Killed)
		expect(received).toBe("payload")
	end)
end)

describe("Hurtbox:MoveTo", function()
	it("moves the bounds and keeps the size", function()
		local hurtbox = makeHurtbox()

		hurtbox:MoveTo(Vector2.new(20, 30))

		expect(hurtbox:GetBounds().Center).toEqual(Vector2.new(20, 30))
		expect(hurtbox:GetBounds().Size).toEqual(Vector2.new(2, 4))
	end)
end)

describe("Hurtbox:Resize", function()
	it("changes the size and keeps the center", function()
		local hurtbox = makeHurtbox()

		hurtbox:Resize(Vector2.new(8, 9))

		expect(hurtbox:GetBounds().Size).toEqual(Vector2.new(8, 9))
		expect(hurtbox:GetBounds().Center).toEqual(Vector2.new(5, 6))
	end)

	it("rejects a size that is not positive on both axes", function()
		local hurtbox = makeHurtbox()

		expect(function()
			hurtbox:Resize(Vector2.new(0, 1))
		end).toThrow()
	end)
end)

describe("Hurtbox:GetBounds", function()
	it("hands back the same box until the hurtbox moves", function()
		local hurtbox = makeHurtbox()

		expect(hurtbox:GetBounds()).toBe(hurtbox:GetBounds())
		local before = hurtbox:GetBounds()
		hurtbox:MoveTo(Vector2.new(1, 1))
		expect(hurtbox:GetBounds()).never.toBe(before)
	end)
end)
