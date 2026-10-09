--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local MockerUtils = require(ReplicatedStorage.Tests.TestUtils.MockUtils)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNController = require(RKMNControllerFolder.RKMNController)
local KinematicWorld = require(RKMNControllerFolder.KinematicWorld)

local TimerUtility = require(RKMNControllerFolder.TimerUtility)
local InputController = require(RKMNControllerFolder.InputController)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)

-- Subsystems in the order _processEntity is expected to run them.
-- `method` is the method the world calls; `takesDt` is whether it receives deltaTime.
local SUBSYSTEMS = {
	{ field = "TimerUtility", class = TimerUtility, method = "Step", takesDt = true },
	{ field = "InputController", class = InputController, method = "Poll", takesDt = true },
	{ field = "CollisionQuery", class = CollisionQuery, method = "UpdateState", takesDt = false },
	{ field = "MovementStateMachine", class = MovementStateMachine, method = "Update", takesDt = true },
	{ field = "PhysicsResolver", class = PhysicsResolver, method = "Resolve", takesDt = true },
}

-- BindToRenderStep only exists on the client; Start/Stop tests are skipped elsewhere
local describeOnClient = if RunService:IsClient() then describe else describe.skip

describe("KinematicWorld", function()
	local world
	local callLog

	-- RunService is an Instance, so its methods can't be stubbed. Instead we probe whether a
	-- name is bound: binding the same name twice errors, so a failed bind means "already bound".
	local function isBound(name)
		local ok = pcall(function()
			RunService:BindToRenderStep(name, Enum.RenderPriority.First.Value, function() end)
		end)

		if ok then
			RunService:UnbindFromRenderStep(name)
		end

		return not ok
	end

	local function newUniqueBindName()
		return "KinematicWorldTest_" .. HttpService:GenerateGUID(false)
	end

	-- Builds a mock controller out of MockerUtils mocks.
	-- Every mocked method appends "<id>:<field>" to callLog so call order can be asserted.
	-- Returns the controller instance plus the jest mocks and subsystem instances by field name.
	local function makeController(id, omitted)
		omitted = omitted or {}

		local subsystemInstances = {}
		local mocks = {}

		for _, subsystem in ipairs(SUBSYSTEMS) do
			if not omitted[subsystem.field] then
				local mock = MockerUtils.createMockClass(subsystem.class)
				mock.Mocks[subsystem.method].mockImplementation(function()
					table.insert(callLog, id .. ":" .. subsystem.field)
				end)

				subsystemInstances[subsystem.field] = mock.Instance
				mocks[subsystem.field] = mock.Mocks[subsystem.method]
			end
		end

		local controller = MockerUtils.createMockClass(RKMNController, subsystemInstances)

		return {
			Instance = controller.Instance,
			Mocks = mocks,
			Subsystems = subsystemInstances,
		}
	end

	-- The call log we expect for the given controller ids, optionally skipping one subsystem
	local function expectedLog(ids, omittedField)
		local expected = {}

		for _, id in ipairs(ids) do
			for _, subsystem in ipairs(SUBSYSTEMS) do
				if subsystem.field ~= omittedField then
					table.insert(expected, id .. ":" .. subsystem.field)
				end
			end
		end

		return expected
	end

	-- Argument `argIndex` (1 is `self`) of the nth call to a jest mock
	local function callArg(mock, callIndex, argIndex)
		return mock.mock.calls[callIndex][argIndex]
	end

	beforeEach(function()
		callLog = {}
		world = KinematicWorld.new()
		-- Unique name so tests never collide with each other or with a live world
		world._runserviceBindName = newUniqueBindName()
	end)

	afterEach(function()
		-- Tests that call Destroy() themselves set `world` to nil
		if world then
			world:Destroy()
		end
	end)

	describe("new", function()
		it("should start with no players", function()
			expect(#world._players).toBe(0)
		end)

		it("should start not running", function()
			expect(world._isRunning).toBe(false)
		end)

		it("should default to the master kinematic loop bind name", function()
			local freshWorld = KinematicWorld.new()

			expect(freshWorld._runserviceBindName).toBe("MasterKinematicLoop")

			freshWorld:Destroy()
		end)
	end)

	describe("RegisterPlayer", function()
		it("should add the controller to the world", function()
			local player = makeController("1")

			world:RegisterPlayer(player.Instance)

			expect(#world._players).toBe(1)
			expect(world._players[1]).toBe(player.Instance)
		end)

		it("should keep controllers in registration order", function()
			local first = makeController("1")
			local second = makeController("2")
			local third = makeController("3")

			world:RegisterPlayer(first.Instance)
			world:RegisterPlayer(second.Instance)
			world:RegisterPlayer(third.Instance)

			expect(world._players[1]).toBe(first.Instance)
			expect(world._players[2]).toBe(second.Instance)
			expect(world._players[3]).toBe(third.Instance)
		end)
	end)

	describe("StepWorld", function()
		it("should do nothing when no players are registered", function()
			expect(function()
				world:StepWorld(1 / 60)
			end).never.toThrow()
		end)

		it("should call every subsystem once for a registered player", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(1 / 60)

			for _, subsystem in ipairs(SUBSYSTEMS) do
				expect(player.Mocks[subsystem.field]).toHaveBeenCalledTimes(1)
			end
		end)

		it("should run the subsystems in timer, input, collision, state machine, physics order", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(1 / 60)

			expect(callLog).toEqual(expectedLog({ "1" }))
		end)

		it("should call each method on the controller's own subsystem instance", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(1 / 60)

			for _, subsystem in ipairs(SUBSYSTEMS) do
				expect(callArg(player.Mocks[subsystem.field], 1, 1)).toBe(player.Subsystems[subsystem.field])
			end
		end)

		it("should pass deltaTime to the subsystems that take it", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)
			local dt = 0.0125

			world:StepWorld(dt)

			for _, subsystem in ipairs(SUBSYSTEMS) do
				if subsystem.takesDt then
					expect(callArg(player.Mocks[subsystem.field], 1, 2)).toBeCloseTo(dt, 5)
				end
			end
		end)

		it("should not pass deltaTime to CollisionQuery:UpdateState", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(0.5)

			-- Only `self` is passed
			expect(#player.Mocks.CollisionQuery.mock.calls[1]).toBe(1)
		end)

		it("should step every registered player once, one player at a time in registration order", function()
			local first = makeController("1")
			local second = makeController("2")
			local third = makeController("3")
			world:RegisterPlayer(first.Instance)
			world:RegisterPlayer(second.Instance)
			world:RegisterPlayer(third.Instance)

			world:StepWorld(1 / 60)

			expect(callLog).toEqual(expectedLog({ "1", "2", "3" }))
		end)

		it("should step on every call, using that call's deltaTime", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(0.01)
			world:StepWorld(0.02)

			local timerStep = player.Mocks.TimerUtility
			expect(timerStep).toHaveBeenCalledTimes(2)
			expect(callArg(timerStep, 1, 2)).toBeCloseTo(0.01, 5)
			expect(callArg(timerStep, 2, 2)).toBeCloseTo(0.02, 5)
		end)

		it("should include players registered after earlier steps", function()
			local early = makeController("1")
			world:RegisterPlayer(early.Instance)
			world:StepWorld(1 / 60)

			local late = makeController("2")
			world:RegisterPlayer(late.Instance)
			callLog = {}
			world:StepWorld(1 / 60)

			expect(callLog).toEqual(expectedLog({ "1", "2" }))
		end)

		it("should skip a controller that has no subsystems", function()
			local omitAll = {}
			for _, subsystem in ipairs(SUBSYSTEMS) do
				omitAll[subsystem.field] = true
			end
			local bare = makeController("1", omitAll)
			world:RegisterPlayer(bare.Instance)

			expect(function()
				world:StepWorld(1 / 60)
			end).never.toThrow()
			expect(#callLog).toBe(0)
		end)

		for _, omitted in ipairs(SUBSYSTEMS) do
			it("should still run the other subsystems when " .. omitted.field .. " is missing", function()
				local player = makeController("1", { [omitted.field] = true })
				world:RegisterPlayer(player.Instance)

				expect(function()
					world:StepWorld(1 / 60)
				end).never.toThrow()

				expect(callLog).toEqual(expectedLog({ "1" }, omitted.field))
			end)
		end

		it("should keep stepping other players when one has a missing subsystem", function()
			local incomplete = makeController("1", { InputController = true })
			local complete = makeController("2")
			world:RegisterPlayer(incomplete.Instance)
			world:RegisterPlayer(complete.Instance)

			world:StepWorld(1 / 60)

			local expected = expectedLog({ "1" }, "InputController")
			for _, entry in ipairs(expectedLog({ "2" })) do
				table.insert(expected, entry)
			end
			expect(callLog).toEqual(expected)
		end)

		it("should work without the world having been started", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)
			expect(world._isRunning).toBe(false)

			world:StepWorld(1 / 60)

			expect(player.Mocks.PhysicsResolver).toHaveBeenCalledTimes(1)
		end)
	end)

	describeOnClient("Start / Stop", function()
		it("should bind the frame loop on Start", function()
			world:Start()

			expect(isBound(world._runserviceBindName)).toBe(true)
		end)

		it("should be safe to call Start twice", function()
			world:Start()

			-- A second bind with the same name would throw, so this checks Start returns early
			expect(function()
				world:Start()
			end).never.toThrow()
			expect(isBound(world._runserviceBindName)).toBe(true)
		end)

		it("should unbind the frame loop on Stop", function()
			world:Start()

			world:Stop()

			expect(isBound(world._runserviceBindName)).toBe(false)
		end)

		it("should be safe to call Stop when never started", function()
			expect(function()
				world:Stop()
			end).never.toThrow()
		end)

		it("should be safe to call Stop twice", function()
			world:Start()
			world:Stop()

			expect(function()
				world:Stop()
			end).never.toThrow()
		end)

		it("should be able to restart after Stop", function()
			world:Start()
			world:Stop()

			expect(function()
				world:Start()
			end).never.toThrow()
			expect(isBound(world._runserviceBindName)).toBe(true)
		end)

		it("should allow two worlds with different bind names to run at once", function()
			local other = KinematicWorld.new()
			other._runserviceBindName = newUniqueBindName()

			world:Start()
			expect(function()
				other:Start()
			end).never.toThrow()

			expect(isBound(world._runserviceBindName)).toBe(true)
			expect(isBound(other._runserviceBindName)).toBe(true)

			other:Destroy()
		end)

		it("should step registered players every frame while running", function()
			-- NOTE: currently fails: the bound callback calls self:_stepWorld, which was renamed
			-- to StepWorld, so the callback errors on every frame
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:Start()
			-- Two heartbeats guarantee at least one full render step ran in between
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()

			expect(player.Mocks.TimerUtility).toHaveBeenCalled()
			expect(callArg(player.Mocks.TimerUtility, 1, 2)).toBeGreaterThan(0)
		end)

		it("should stop stepping players after Stop", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)
			world:Start()
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()
			world:Stop()
			local callsAtStop = #player.Mocks.TimerUtility.mock.calls

			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()

			expect(#player.Mocks.TimerUtility.mock.calls).toBe(callsAtStop)
		end)
	end)

	describe("Destroy", function()
		it("should clear the registered players", function()
			world:RegisterPlayer(makeController("1").Instance)
			world:RegisterPlayer(makeController("2").Instance)
			local players = world._players

			world:Destroy()
			world = nil

			expect(#players).toBe(0)
		end)

		it("should freeze the world and strip its metatable", function()
			local target = world

			world:Destroy()
			world = nil

			expect(table.isfrozen(target)).toBe(true)
			expect(getmetatable(target)).toBeNil()
		end)

		it("should be safe to destroy a world that was never started", function()
			expect(function()
				world:Destroy()
				world = nil
			end).never.toThrow()
		end)
	end)

	describeOnClient("Destroy while running", function()
		it("should unbind the frame loop", function()
			local bindName = world._runserviceBindName
			world:Start()

			world:Destroy()
			world = nil

			expect(isBound(bindName)).toBe(false)
		end)

		it("should stop stepping players", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)
			world:Start()
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()

			world:Destroy()
			world = nil
			local callsAtDestroy = #player.Mocks.TimerUtility.mock.calls
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()

			expect(#player.Mocks.TimerUtility.mock.calls).toBe(callsAtDestroy)
		end)
	end)
end)