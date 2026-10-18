--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DamageTemplate = require(ReplicatedStorage.Combat.Data.DamageTemplate)
local ProjectileDefinition = require(ReplicatedStorage.Combat.Projectile.ProjectileDefinition)
local ProjectileIDs = require(ReplicatedStorage.Combat.Projectile.ProjectileIDRegistry)

local function makeConfig(overrides)
	local config = {
		Id = ProjectileIDs.MegaBusterLemon,
		Speed = 60,
		Lifetime = 1.2,
		Size = Vector2.new(1, 1),
		Damage = DamageTemplate.new({ Amount = 1 }),
	}
	for key, value in overrides or {} do
		config[key] = value
	end
	return config
end

describe("ProjectileDefinition.new", function()
	it("keeps the values it is given", function()
		local config = makeConfig({ TargetPenetrationLimit = 2 })
		local definition = ProjectileDefinition.new(config)

		expect(definition.Id).toBe(ProjectileIDs.MegaBusterLemon)
		expect(definition.Speed).toBe(60)
		expect(definition.Lifetime).toBe(1.2)
		expect(definition.Size).toEqual(Vector2.new(1, 1))
		expect(definition.Damage).toBe(config.Damage)
		expect(definition.TargetPenetrationLimit).toBe(2)
	end)

	it("defaults the penetration limit to 0", function()
		expect(ProjectileDefinition.new(makeConfig()).TargetPenetrationLimit).toBe(0)
	end)

	it("freezes the definition", function()
		expect(table.isfrozen(ProjectileDefinition.new(makeConfig()))).toBe(true)
	end)

	it("rejects a speed that is not positive", function()
		expect(function()
			ProjectileDefinition.new(makeConfig({ Speed = 0 }))
		end).toThrow()
	end)

	it("rejects a lifetime that is not positive", function()
		expect(function()
			ProjectileDefinition.new(makeConfig({ Lifetime = 0 }))
		end).toThrow()
	end)

	it("rejects a size that is not positive on both axes", function()
		expect(function()
			ProjectileDefinition.new(makeConfig({ Size = Vector2.new(1, 0) }))
		end).toThrow()
		expect(function()
			ProjectileDefinition.new(makeConfig({ Size = Vector2.new(0, 1) }))
		end).toThrow()
	end)

	it("rejects a negative penetration limit", function()
		expect(function()
			ProjectileDefinition.new(makeConfig({ TargetPenetrationLimit = -1 }))
		end).toThrow()
	end)
end)
