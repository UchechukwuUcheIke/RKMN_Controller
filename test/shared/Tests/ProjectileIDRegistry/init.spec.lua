--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ProjectileIDs = require(ReplicatedStorage.Combat.Projectile.ProjectileIDRegistry)

describe("ProjectileIDRegistry", function()
	it("is frozen", function()
		expect(table.isfrozen(ProjectileIDs)).toBe(true)
	end)

	it("maps every name to the same string", function()
		for name, id in ProjectileIDs do
			expect(id).toBe(name)
		end
	end)
end)
