--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local StateAnimationBinder = require(ReplicatedStorage.RKMNController.AnimationController.StateAnimationBinder)

local function makeEntry(id)
	return {
		AnimationId = id,
		IsLooped = true,
		Priority = Enum.AnimationPriority.Movement,
	}
end

-- Stands in for AnimationTrackPlayer: records what it was asked to do.
local function createTrackPlayerStub()
	local player = { calls = {} }

	function player:Play(entry)
		table.insert(self.calls, { "Play", entry.AnimationId })
	end

	function player:Stop()
		table.insert(self.calls, { "Stop" })
	end

	return player
end

local function createMovementFSMStub(currentStateId)
	return {
		CurrentStateId = currentStateId,
		OnStateChanged = Signal.new(),
	}
end

describe("StateAnimationBinder", function()
	local animationSet
	local trackPlayer
	local fsm

	beforeEach(function()
		animationSet = {
			Idle = makeEntry("rbxassetid://idle"),
			Walk = makeEntry("rbxassetid://walk"),
			Dash = makeEntry(""),
		}
		trackPlayer = createTrackPlayerStub()
		fsm = createMovementFSMStub("Idle")
	end)

	describe("new", function()
		it("should play the animation for the state the machine is already in", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer)

			expect(trackPlayer.calls).toEqual({ { "Play", "rbxassetid://idle" } })
		end)

		it("should play nothing when the machine has no current state yet", function()
			fsm = createMovementFSMStub(nil)

			StateAnimationBinder.new(fsm, animationSet, trackPlayer)

			expect(#trackPlayer.calls).toBe(0)
		end)
	end)

	describe("state changes", function()
		it("should play the new state's animation", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer)

			fsm.OnStateChanged:Fire("Walk")

			expect(trackPlayer.calls[2]).toEqual({ "Play", "rbxassetid://walk" })
		end)

		it("should stop the current animation when the state's entry has no animation id", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer)

			fsm.OnStateChanged:Fire("Dash")

			expect(trackPlayer.calls[2][1]).toBe("Stop")
		end)

		it("should stop the current animation when the state has no entry at all", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer)

			fsm.OnStateChanged:Fire("Stun")

			expect(trackPlayer.calls[2][1]).toBe("Stop")
		end)
	end)

	describe("Destroy", function()
		it("should stop reacting to state changes", function()
			local binder = StateAnimationBinder.new(fsm, animationSet, trackPlayer)
			binder:Destroy()

			fsm.OnStateChanged:Fire("Walk")

			expect(#trackPlayer.calls).toBe(1)
		end)
	end)
end)
