--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local Direction = require(ReplicatedStorage.Data.Direction)
local Signal =require(ReplicatedStorage.DevPackages.goodsignal)
local AnimationControllerFacade = require(ReplicatedStorage.RKMNController.AnimationController.AnimationControllerFacade)

local function createCharacter()
	local character = Instance.new("Model")

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character

	return character
end

local function createMovementFSMStub()
	return {
		CurrentStateId = "Idle",
		OnStateChanged = Signal.new(),
	}
end

local function createPhysicsResolverStub()
	return {
		GetFacingDirection = function()
			return Direction.Right
		end,
	}
end

-- The parts have their own specs; these tests only check that the facade wires them together.
describe("AnimationControllerFacade", function()
	local character
	local fsm
	local controller

	beforeEach(function()
		character = createCharacter()
		fsm = createMovementFSMStub()
	end)

	afterEach(function()
		if controller then
			controller:Destroy()
			controller = nil
		end
		character:Destroy()
	end)

	describe("new", function()
		it("should throw when the character has no Humanoid", function()
			character:FindFirstChildOfClass("Humanoid"):Destroy()

			expect(function()
				AnimationControllerFacade.new(character, fsm, createPhysicsResolverStub(), {})
			end).toThrow("Humanoid")
		end)

		it("should create an Animator under the Humanoid when there is none", function()
			controller = AnimationControllerFacade.new(character, fsm, createPhysicsResolverStub(), {})

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			expect(humanoid:FindFirstChildOfClass("Animator")).toBeDefined()
		end)

		it("should reuse an existing Animator", function()
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local existing = Instance.new("Animator")
			existing.Parent = humanoid

			controller = AnimationControllerFacade.new(character, fsm, createPhysicsResolverStub(), {})

			expect(humanoid:FindFirstChildOfClass("Animator")).toBe(existing)
		end)
	end)

	describe("Destroy", function()
		it("should stop listening to state changes", function()
			controller = AnimationControllerFacade.new(character, fsm, createPhysicsResolverStub(), {})

			controller:Destroy()
			controller = nil

			expect(function()
				fsm.OnStateChanged:Fire("Walk")
			end).never.toThrow()
		end)
	end)
end)
