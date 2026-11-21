--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Direction = require(ReplicatedStorage.Data.Direction)
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local StateAnimationBinder = require(ReplicatedStorage.RKMNController.AnimationController.StateAnimationBinder)

local function makeEntry(id)
	return {
		AnimationId = id,
		IsLooped = true,
		Priority = Enum.AnimationPriority.Movement,
	}
end

local function makeDirectionalEntry(leftId, rightId)
	return {
		Left = makeEntry(leftId),
		Right = makeEntry(rightId),
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
	local facingDirection
	local function getFacingDirection()
		return facingDirection
	end

	beforeEach(function()
		animationSet = {
			Idle = makeDirectionalEntry("rbxassetid://idleLeft", "rbxassetid://idleRight"),
			Walk = makeDirectionalEntry("rbxassetid://walkLeft", "rbxassetid://walkRight"),
			Dash = makeDirectionalEntry("", ""),
		}
		trackPlayer = createTrackPlayerStub()
		fsm = createMovementFSMStub("Idle")
		facingDirection = Direction.Right
	end)

	describe("new", function()
		it("should play the animation for the state the machine is already in", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			expect(trackPlayer.calls).toEqual({ { "Play", "rbxassetid://idleRight" } })
		end)

		it("should play the left animation when already facing left", function()
			facingDirection = Direction.Left

			StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			expect(trackPlayer.calls).toEqual({ { "Play", "rbxassetid://idleLeft" } })
		end)

		it("should play nothing when the machine has no current state yet", function()
			fsm = createMovementFSMStub(nil)

			StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			expect(#trackPlayer.calls).toBe(0)
		end)
	end)

	describe("state changes", function()
		it("should play the new state's animation for the current facing", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			facingDirection = Direction.Left
			fsm.OnStateChanged:Fire("Walk")

			expect(trackPlayer.calls[2]).toEqual({ "Play", "rbxassetid://walkLeft" })
		end)

		it("should stop the current animation when the facing's entry has no animation id", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			fsm.OnStateChanged:Fire("Dash")

			expect(trackPlayer.calls[2][1]).toBe("Stop")
		end)

		it("should stop the current animation when the state has no entry at all", function()
			StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			fsm.OnStateChanged:Fire("Stun")

			expect(trackPlayer.calls[2][1]).toBe("Stop")
		end)
	end)

	describe("Update", function()
		it("should switch to the other side's animation when the facing changes", function()
			local binder = StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			facingDirection = Direction.Left
			binder:Update()

			expect(trackPlayer.calls[2]).toEqual({ "Play", "rbxassetid://idleLeft" })
		end)

		it("should do nothing while the facing is unchanged", function()
			local binder = StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			binder:Update()
			binder:Update()

			expect(#trackPlayer.calls).toBe(1)
		end)

		it("should not re-pick again once the new facing has been played", function()
			local binder = StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			facingDirection = Direction.Left
			binder:Update()
			binder:Update()

			expect(#trackPlayer.calls).toBe(2)
		end)

		it("should do nothing before any state has been entered", function()
			fsm = createMovementFSMStub(nil)
			local binder = StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)

			facingDirection = Direction.Left
			binder:Update()

			expect(#trackPlayer.calls).toBe(0)
		end)

		it("should follow the state it last changed to", function()
			local binder = StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)
			fsm.OnStateChanged:Fire("Walk")

			facingDirection = Direction.Left
			binder:Update()

			expect(trackPlayer.calls[3]).toEqual({ "Play", "rbxassetid://walkLeft" })
		end)
	end)

	describe("Destroy", function()
		it("should stop reacting to state changes", function()
			local binder = StateAnimationBinder.new(fsm, animationSet, trackPlayer, getFacingDirection)
			binder:Destroy()

			fsm.OnStateChanged:Fire("Walk")

			expect(#trackPlayer.calls).toBe(1)
		end)
	end)
end)
