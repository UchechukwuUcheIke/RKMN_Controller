--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlPreferenceRateLimiter = require(ServerScriptService.Server.Telemetry.ControlPreferences.ControlPreferenceRateLimiter)

local function makeLimiter(cooldownSeconds, maxPerPlayer)
	local now = 0
	local limiter = ControlPreferenceRateLimiter.new(cooldownSeconds, maxPerPlayer, function()
		return now
	end)
	local function advance(seconds)
		now += seconds
	end
	return limiter, advance
end

-- Players are only used as table keys here, so plain tables stand in for them.
local PLAYER_A = {}
local PLAYER_B = {}

describe("ControlPreferenceRateLimiter.TryAccept", function()
	it("accepts a player's first report", function()
		local limiter = makeLimiter(5, 20)

		expect(limiter:TryAccept(PLAYER_A)).toBe(true)
	end)

	it("refuses a second report inside the cooldown", function()
		local limiter, advance = makeLimiter(5, 20)
		limiter:TryAccept(PLAYER_A)
		advance(4.9)

		expect(limiter:TryAccept(PLAYER_A)).toBe(false)
	end)

	it("accepts again once the cooldown has passed", function()
		local limiter, advance = makeLimiter(5, 20)
		limiter:TryAccept(PLAYER_A)
		advance(5)

		expect(limiter:TryAccept(PLAYER_A)).toBe(true)
	end)

	it("does not restart the cooldown on a refused report", function()
		local limiter, advance = makeLimiter(5, 20)
		limiter:TryAccept(PLAYER_A)
		advance(3)
		limiter:TryAccept(PLAYER_A)
		advance(2)

		expect(limiter:TryAccept(PLAYER_A)).toBe(true)
	end)

	it("tracks each player separately", function()
		local limiter = makeLimiter(5, 20)
		limiter:TryAccept(PLAYER_A)

		expect(limiter:TryAccept(PLAYER_B)).toBe(true)
	end)

	it("stops accepting once a player reaches the cap", function()
		local limiter, advance = makeLimiter(1, 2)
		expect(limiter:TryAccept(PLAYER_A)).toBe(true)
		advance(1)
		expect(limiter:TryAccept(PLAYER_A)).toBe(true)
		advance(1)

		expect(limiter:TryAccept(PLAYER_A)).toBe(false)
	end)
end)

describe("ControlPreferenceRateLimiter.Forget", function()
	it("lets a player report again straight away", function()
		local limiter = makeLimiter(5, 1)
		limiter:TryAccept(PLAYER_A)
		limiter:Forget(PLAYER_A)

		expect(limiter:TryAccept(PLAYER_A)).toBe(true)
	end)
end)
