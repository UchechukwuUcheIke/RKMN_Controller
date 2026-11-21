--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local MockerUtils = require(ReplicatedStorage.Tests.TestUtils.MockUtils)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNControllerFacade = require(RKMNControllerFolder.RKMNControllerFacade)

local TimerRegistry = require(RKMNControllerFolder.TimerRegistry)
local PlayerInputFacade = require(ReplicatedStorage.PlayerInput.PlayerInputFacade)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery.CollisionQueryFacade)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver.PhysicsResolverFacade)

-- Subsystems in the order Update is expected to run them.
-- `method` is the method Update calls; `takesDt` is whether it receives deltaTime.
local SUBSYSTEMS = {
	{ field = "TimerRegistry", class = TimerRegistry, method = "Step", takesDt = true },
	{ field = "PlayerInput", class = PlayerInputFacade, method = "Poll", takesDt = true },
	{ field = "CollisionQuery", class = CollisionQuery, method = "UpdateState", takesDt = false },
	{ field = "MovementStateMachine", class = MovementStateMachine, method = "Update", takesDt = true },
	{ field = "PhysicsResolver", class = PhysicsResolver, method = "Resolve", takesDt = true },
}

describe("RKMNControllerFacade", function()
	local callLog
	local controller
	local mocks
	local instances

	beforeEach(function()
		callLog = {}
		mocks = {}
		instances = {}

		for _, subsystem in ipairs(SUBSYSTEMS) do
			local mock = MockerUtils.createMockClass(subsystem.class)
			mock.Mocks[subsystem.method].mockImplementation(function()
				table.insert(callLog, subsystem.field)
			end)
			instances[subsystem.field] = mock.Instance
			mocks[subsystem.field] = mock.Mocks[subsystem.method]
		end

		controller = RKMNControllerFacade.new(instances)
	end)

	describe("Update", function()
		it("should call every subsystem once", function()
			controller:Update(1 / 60)

			for _, subsystem in ipairs(SUBSYSTEMS) do
				expect(mocks[subsystem.field]).toHaveBeenCalledTimes(1)
			end
		end)

		it("should run the subsystems in timer, input, collision, state machine, physics order", function()
			controller:Update(1 / 60)

			local expected = {}
			for _, subsystem in ipairs(SUBSYSTEMS) do
				table.insert(expected, subsystem.field)
			end
			expect(callLog).toEqual(expected)
		end)

		it("should call each method on the controller's own subsystem instance", function()
			controller:Update(1 / 60)

			for _, subsystem in ipairs(SUBSYSTEMS) do
				expect(mocks[subsystem.field].mock.calls[1][1]).toBe(instances[subsystem.field])
			end
		end)

		it("should pass deltaTime to the subsystems that take it", function()
			controller:Update(0.0125)

			for _, subsystem in ipairs(SUBSYSTEMS) do
				if subsystem.takesDt then
					expect(mocks[subsystem.field].mock.calls[1][2]).toBeCloseTo(0.0125, 5)
				end
			end
		end)

		it("should not pass deltaTime to CollisionQuery:UpdateState", function()
			controller:Update(0.5)

			-- Only `self` is passed
			expect(#mocks.CollisionQuery.mock.calls[1]).toBe(1)
		end)

		it("should step again on every call, using that call's deltaTime", function()
			controller:Update(0.01)
			controller:Update(0.02)

			expect(mocks.TimerRegistry).toHaveBeenCalledTimes(2)
			expect(mocks.TimerRegistry.mock.calls[1][2]).toBeCloseTo(0.01, 5)
			expect(mocks.TimerRegistry.mock.calls[2][2]).toBeCloseTo(0.02, 5)
		end)
	end)
end)
