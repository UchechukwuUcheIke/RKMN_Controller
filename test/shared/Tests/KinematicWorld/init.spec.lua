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
local KinematicWorld = require(ReplicatedStorage.KinematicWorld)



describe("KinematicWorld", function()
	local world
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
		world = KinematicWorld.new()
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

		it("should not step the player until StepWorld is called", function()
			local player = makeController("1")

			world:RegisterPlayer(player.Instance)

			expect(#callLog).toBe(0)
		end)
	end)

	describe("StepWorld", function()
		it("should do nothing when no players are registered", function()
			expect(function()
				world:StepWorld(1 / 60)
			end).never.toThrow()
		end)

		it("should call Update once on a registered player", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(1 / 60)

			expect(player.Update).toHaveBeenCalledTimes(1)
			expect(player.Update.mock.calls[1][1]).toBe(player.Instance)
		end)

		it("should pass deltaTime to Update", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(0.0125)

			expect(player.Update.mock.calls[1][2]).toBeCloseTo(0.0125, 5)
		end)

		it("should update every registered player once, in registration order", function()
			world:RegisterPlayer(makeController("1").Instance)
			world:RegisterPlayer(makeController("2").Instance)
			world:RegisterPlayer(makeController("3").Instance)

			world:StepWorld(1 / 60)

			expect(callLog).toEqual({ "1", "2", "3" })
		end)

		it("should update on every call, using that call's deltaTime", function()
			local player = makeController("1")
			world:RegisterPlayer(player.Instance)

			world:StepWorld(0.01)
			world:StepWorld(0.02)

			expect(player.Update).toHaveBeenCalledTimes(2)
			expect(player.Update.mock.calls[1][2]).toBeCloseTo(0.01, 5)
			expect(player.Update.mock.calls[2][2]).toBeCloseTo(0.02, 5)
		end)

		it("should include players registered after earlier steps", function()
			world:RegisterPlayer(makeController("1").Instance)
			world:StepWorld(1 / 60)

			world:RegisterPlayer(makeController("2").Instance)
			callLog = {}
			world:StepWorld(1 / 60)

			expect(callLog).toEqual({ "1", "2" })
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

		it("should not step or touch any subsystem", function()
			world:RegisterPlayer(makeController("1").Instance)
			world:RegisterPlayer(makeController("2").Instance)

			world:Destroy()
			world = nil

			expect(#callLog).toBe(0)
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
end)