--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)
local Direction = require(ReplicatedStorage.Data.Direction)
local Hitbox = require(ReplicatedStorage.Combat.Hitbox.Hitbox)
local HitResult = require(ReplicatedStorage.Combat.Hurtbox.HitResult)
local Team = require(ReplicatedStorage.Combat.Data.Team)

local function makeHitbox(overrides)
	local config = {
		OwnerId = 1,
		Team = Team.Player,
		Center = Vector2.new(0, 0),
		Size = Vector2.new(2, 2),
		Damage = DamageTemplate.new({ Amount = 1 }),
		Direction = Direction.Right,
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return Hitbox.new(config)
end

local function makeHurtbox()
	return {
		OwnerId = 2,
		Team = Team.Enemy,
		Enabled = true,
		GetBounds = function() end,
		Receive = function()
			return HitResult.Applied
		end,
	}
end

describe("Hitbox.new", function()
	it("keeps the values it is given", function()
		local hitbox = makeHitbox({ OwnerId = 7, Team = Team.Enemy, Center = Vector2.new(3, 4), Size = Vector2.new(5, 6) })

		expect(hitbox.OwnerId).toBe(7)
		expect(hitbox.Team).toBe(Team.Enemy)
		expect(hitbox:GetCenter()).toEqual(Vector2.new(3, 4))
		expect(hitbox.Size).toEqual(Vector2.new(5, 6))
	end)

	it("keeps the damage, direction and hit callback", function()
		local damage = DamageTemplate.new({ Amount = 3 })
		local onHit = function() end
		local hitbox = makeHitbox({ Damage = damage, Direction = Direction.Left, OnHit = onHit })

		expect(hitbox.Damage).toBe(damage)
		expect(hitbox.Direction).toBe(Direction.Left)
		expect(hitbox.OnHit).toBe(onHit)
	end)

	it("can reach all the way along its move to begin with", function()
		expect(makeHitbox().ReachFraction).toBe(1)
	end)

	it("is enabled unless the config says otherwise", function()
		expect(makeHitbox().Enabled).toBe(true)
		expect(makeHitbox({ Enabled = false }).Enabled).toBe(false)
	end)

	it("starts with nowhere to sweep from", function()
		local hitbox = makeHitbox({ Center = Vector2.new(3, 4) })

		expect(hitbox:GetPreviousCenter()).toEqual(Vector2.new(3, 4))
	end)

	it("rejects a size that is not positive on both axes", function()
		expect(function()
			makeHitbox({ Size = Vector2.new(0, 2) })
		end).toThrow()
		expect(function()
			makeHitbox({ Size = Vector2.new(2, 0) })
		end).toThrow()
	end)
end)

describe("Hitbox movement", function()
	it("remembers where it came from when it moves", function()
		local hitbox = makeHitbox()

		hitbox:MoveTo(Vector2.new(10, 0))

		expect(hitbox:GetCenter()).toEqual(Vector2.new(10, 0))
		expect(hitbox:GetPreviousCenter()).toEqual(Vector2.new(0, 0))
	end)

	it("only remembers the move before the latest one", function()
		local hitbox = makeHitbox()

		hitbox:MoveTo(Vector2.new(10, 0))
		hitbox:MoveTo(Vector2.new(15, 0))

		expect(hitbox:GetPreviousCenter()).toEqual(Vector2.new(10, 0))
	end)

	it("teleports without sweeping", function()
		local hitbox = makeHitbox()
		hitbox:MoveTo(Vector2.new(10, 0))

		hitbox:Teleport(Vector2.new(50, 0))

		expect(hitbox:GetCenter()).toEqual(Vector2.new(50, 0))
		expect(hitbox:GetPreviousCenter()).toEqual(Vector2.new(50, 0))
	end)
end)

describe("Hitbox:GetSweptBounds", function()
	it("is just the hitbox when it has not moved", function()
		local bounds = makeHitbox({ Center = Vector2.new(3, 4), Size = Vector2.new(2, 2) }):GetSweptBounds()

		expect(bounds.Center).toEqual(Vector2.new(3, 4))
		expect(bounds.Size).toEqual(Vector2.new(2, 2))
	end)

	it("stretches to cover the ground since the last move", function()
		local hitbox = makeHitbox({ Size = Vector2.new(2, 2) })
		hitbox:MoveTo(Vector2.new(10, 0))

		local bounds = hitbox:GetSweptBounds()

		expect(bounds.Center).toEqual(Vector2.new(5, 0))
		expect(bounds.Size).toEqual(Vector2.new(12, 2))
	end)

	it("stretches the same way moving backwards", function()
		local hitbox = makeHitbox({ Center = Vector2.new(10, 0), Size = Vector2.new(2, 2) })
		hitbox:MoveTo(Vector2.new(0, 0))

		local bounds = hitbox:GetSweptBounds()

		expect(bounds.Center).toEqual(Vector2.new(5, 0))
		expect(bounds.Size).toEqual(Vector2.new(12, 2))
	end)

	it("follows a resize", function()
		local hitbox = makeHitbox()
		hitbox:Resize(Vector2.new(4, 6))

		expect(hitbox:GetSweptBounds().Size).toEqual(Vector2.new(4, 6))
	end)
end)

describe("Hitbox:SetReachFraction", function()
	it("limits how far the hitbox can reach", function()
		local hitbox = makeHitbox()

		hitbox:SetReachFraction(0.4)

		expect(hitbox.ReachFraction).toBe(0.4)
	end)

	it("rejects a fraction outside 0 to 1", function()
		expect(function()
			makeHitbox():SetReachFraction(-0.1)
		end).toThrow()
		expect(function()
			makeHitbox():SetReachFraction(1.1)
		end).toThrow()
	end)
end)

describe("Hitbox:Resize", function()
	it("rejects a size that is not positive on both axes", function()
		expect(function()
			makeHitbox():Resize(Vector2.new(-1, 2))
		end).toThrow()
	end)
end)

describe("Hitbox hit memory", function()
	it("has hit nothing to begin with", function()
		expect(makeHitbox():HasHit(makeHurtbox())).toBe(false)
	end)

	it("remembers a hurtbox it recorded", function()
		local hitbox = makeHitbox()
		local struck = makeHurtbox()

		hitbox:RecordHit(struck)

		expect(hitbox:HasHit(struck)).toBe(true)
		expect(hitbox:HasHit(makeHurtbox())).toBe(false)
	end)
end)
