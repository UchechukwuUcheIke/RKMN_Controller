--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local RKMNControllerFolder = ReplicatedStorage.RKMNController
local MovementAnimationSet = require(RKMNControllerFolder.AnimationController.MovementAnimationSet)
local MovementStateIDs = require(RKMNControllerFolder.MovementStateIDs)

describe("MovementAnimationSet", function()
	it("should have an entry for every movement state", function()
		for _, stateId in MovementStateIDs do
			expect(MovementAnimationSet[stateId]).toBeDefined()
		end
	end)

	it("should give every entry the fields the track player needs", function()
		for _, entry in MovementAnimationSet do
			expect(type(entry.AnimationId)).toBe("string")
			expect(type(entry.IsLooped)).toBe("boolean")
			expect(typeof(entry.Priority)).toBe("EnumItem")
		end
	end)

	it("should be read-only", function()
		expect(table.isfrozen(MovementAnimationSet)).toBe(true)
	end)
end)
