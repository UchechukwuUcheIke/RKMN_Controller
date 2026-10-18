--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DamagePayload = require(ReplicatedStorage.Combat.Data.DamagePayload)
local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)
local Direction = require(ReplicatedStorage.Data.Direction)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local function makeConfig(overrides)
	local config = {
		Amount = 3,
		SourceOwnerId = 7,
		Team = Team.Player,
		Knockback = Vector2.new(5, 2),
		HitstopDuration = 0.05,
		Tags = { "Buster" },
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return config
end

describe("DamagePayload.new", function()
	it("keeps the values it is given", function()
		local payload = DamagePayload.new(makeConfig())

		expect(payload.Amount).toBe(3)
		expect(payload.SourceOwnerId).toBe(7)
		expect(payload.Team).toBe(Team.Player)
		expect(payload.Knockback).toEqual(Vector2.new(5, 2))
		expect(payload.HitstopDuration).toBe(0.05)
		expect(payload.Tags).toEqual({ "Buster" })
	end)

	it("freezes the payload and its tags", function()
		local payload = DamagePayload.new(makeConfig())

		expect(table.isfrozen(payload)).toBe(true)
		expect(table.isfrozen(payload.Tags)).toBe(true)
	end)

	it("does not freeze a tags table the caller passed in", function()
		local tags = { "Buster" }
		DamagePayload.new(makeConfig({ Tags = tags }))

		expect(table.isfrozen(tags)).toBe(false)
	end)

	it("shares tags that are already frozen", function()
		local tags = table.freeze({ "Buster" })

		expect(DamagePayload.new(makeConfig({ Tags = tags })).Tags).toBe(tags)
	end)

	it("rejects a negative amount", function()
		expect(function()
			DamagePayload.new(makeConfig({ Amount = -1 }))
		end).toThrow()
	end)

	it("rejects a negative hitstop duration", function()
		expect(function()
			DamagePayload.new(makeConfig({ HitstopDuration = -0.1 }))
		end).toThrow()
	end)
end)

describe("DamagePayload.fromTemplate", function()
	local template = DamageTemplate.new({
		Amount = 3,
		Knockback = Vector2.new(5, 2),
		HitstopDuration = 0.05,
		Tags = { "Buster" },
	})

	it("fills the payload from the template, owner and team", function()
		local payload = DamagePayload.fromTemplate(template, 7, Team.Player, Direction.Right)

		expect(payload.Amount).toBe(3)
		expect(payload.SourceOwnerId).toBe(7)
		expect(payload.Team).toBe(Team.Player)
		expect(payload.HitstopDuration).toBe(0.05)
		expect(payload.Tags).toBe(template.Tags)
	end)

	it("keeps the knockback as written for a source facing right", function()
		local payload = DamagePayload.fromTemplate(template, 7, Team.Player, Direction.Right)

		expect(payload.Knockback).toEqual(Vector2.new(5, 2))
	end)

	it("mirrors only the horizontal knockback for a source facing left", function()
		local payload = DamagePayload.fromTemplate(template, 7, Team.Player, Direction.Left)

		expect(payload.Knockback).toEqual(Vector2.new(-5, 2))
	end)
end)
