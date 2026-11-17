--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local CollisionTolerances = require(ReplicatedStorage.RKMNController.CollisionTolerances)

describe("CollisionTolerances.Default", function()
    local defaults = CollisionTolerances.Default

    it("sets the ground check distance", function()
        expect(defaults.GroundCheckDistance).toBe(0.05)
    end)

    it("sets the wall check distance", function()
        expect(defaults.WallCheckDistance).toBe(0.05)
    end)

    it("sets the skin width", function()
        expect(defaults.SkinWidth).toBe(0.1)
    end)

    it("sets the max slope angle", function()
        expect(defaults.MaxSlopeAngle).toBe(90)
    end)

    it("is frozen", function()
        expect(table.isfrozen(defaults)).toBe(true)
    end)
end)
