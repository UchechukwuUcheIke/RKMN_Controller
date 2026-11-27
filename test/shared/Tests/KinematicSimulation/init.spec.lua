--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local MockerUtils = require(ReplicatedStorage.Tests.TestUtils.MockUtils)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNControllerFacade = require(RKMNControllerFolder.RKMNControllerFacade)
local KinematicSimulation = require(ReplicatedStorage.KinematicSimulation)



describe("KinematicSimulation", function()
	local simulation
	local callLog

	-- Builds a mock controller whose Update appends "<id>" to callLog so call order can be asserted
	local function makeController(id)
		local controller = MockerUtils.createMockClass(RKMNControllerFacade)
		controller.Mocks.Update.mockImplementation(function()
			table.insert(callLog, id)
		end)

		return {
			Instance = controller.Instance,
			Update = controller.Mocks.Update,
		}
	end

	beforeEach(function()
		callLog = {}
		simulation = KinematicSimulation.new()
	end)

	afterEach(function()
		-- Tests that call Destroy() themselves set `simulation` to nil
		if simulation then
			simulation:Destroy()
		end
	end)

	describe("new", function()
		it("should start with no players", function()
			expect(#simulation._players).toBe(0)
		end)

		it("should start not running", function()
			expect(simulation._isRunning).toBe(false)
		end)

		it("should default to the master kinematic loop bind name", function()
			local freshSimulation = KinematicSimulation.new()

			expect(freshSimulation._runserviceBindName).toBe("MasterKinematicLoop")

			freshSimulation:Destroy()
		end)
	end)

	describe("RegisterPlayer", function()
		it("should add the controller to the simulation", function()
			local player = makeController("1")

			simulation:RegisterPlayer(player.Instance)

			expect(#simulation._players).toBe(1)
			expect(simulation._players[1]).toBe(player.Instance)
		end)

		it("should keep controllers in registration order", function()
			local first = makeController("1")
			local second = makeController("2")
			local third = makeController("3")

			simulation:RegisterPlayer(first.Instance)
			simulation:RegisterPlayer(second.Instance)
			simulation:RegisterPlayer(third.Instance)

			expect(simulation._players[1]).toBe(first.Instance)
			expect(simulation._players[2]).toBe(second.Instance)
			expect(simulation._players[3]).toBe(third.Instance)
		end)

		it("should not step the player until Step is called", function()
			local player = makeController("1")

			simulation:RegisterPlayer(player.Instance)

			expect(#callLog).toBe(0)
		end)
	end)

	describe("Step", function()
		it("should do nothing when no players are registered", function()
			expect(function()
				simulation:Step(1 / 60)
			end).never.toThrow()
		end)

		it("should call Update once on a registered player", function()
			local player = makeController("1")
			simulation:RegisterPlayer(player.Instance)

			simulation:Step(1 / 60)

			expect(player.Update).toHaveBeenCalledTimes(1)
			expect(player.Update.mock.calls[1][1]).toBe(player.Instance)
		end)

		it("should pass deltaTime to Update", function()
			local player = makeController("1")
			simulation:RegisterPlayer(player.Instance)

			simulation:Step(0.0125)

			expect(player.Update.mock.calls[1][2]).toBeCloseTo(0.0125, 5)
		end)

		it("should update every registered player once, in registration order", function()
			simulation:RegisterPlayer(makeController("1").Instance)
			simulation:RegisterPlayer(makeController("2").Instance)
			simulation:RegisterPlayer(makeController("3").Instance)

			simulation:Step(1 / 60)

			expect(callLog).toEqual({ "1", "2", "3" })
		end)

		it("should update on every call, using that call's deltaTime", function()
			local player = makeController("1")
			simulation:RegisterPlayer(player.Instance)

			simulation:Step(0.01)
			simulation:Step(0.02)

			expect(player.Update).toHaveBeenCalledTimes(2)
			expect(player.Update.mock.calls[1][2]).toBeCloseTo(0.01, 5)
			expect(player.Update.mock.calls[2][2]).toBeCloseTo(0.02, 5)
		end)

		it("should include players registered after earlier steps", function()
			simulation:RegisterPlayer(makeController("1").Instance)
			simulation:Step(1 / 60)

			simulation:RegisterPlayer(makeController("2").Instance)
			callLog = {}
			simulation:Step(1 / 60)

			expect(callLog).toEqual({ "1", "2" })
		end)
	end)


	describe("Destroy", function()
		it("should clear the registered players", function()
			simulation:RegisterPlayer(makeController("1").Instance)
			simulation:RegisterPlayer(makeController("2").Instance)
			local players = simulation._players

			simulation:Destroy()
			simulation = nil

			expect(#players).toBe(0)
		end)

		it("should not step or touch any subsystem", function()
			simulation:RegisterPlayer(makeController("1").Instance)
			simulation:RegisterPlayer(makeController("2").Instance)

			simulation:Destroy()
			simulation = nil

			expect(#callLog).toBe(0)
		end)

		it("should freeze the simulation and strip its metatable", function()
			local target = simulation

			simulation:Destroy()
			simulation = nil

			expect(table.isfrozen(target)).toBe(true)
			expect(getmetatable(target)).toBeNil()
		end)

		it("should be safe to destroy a simulation that was never started", function()
			expect(function()
				simulation:Destroy()
				simulation = nil
			end).never.toThrow()
		end)
	end)
end)