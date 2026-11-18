--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local AnimationTrackPlayer = require(ReplicatedStorage.RKMNController.AnimationController.AnimationTrackPlayer)

-- Stands in for an AnimationTrack: records every call made to it.
local function createTrackStub(log, id)
	local track = { Looped = false, Priority = nil }

	function track:Play(fadeTime)
		table.insert(log, { "Play", id, fadeTime })
	end

	function track:Stop(fadeTime)
		table.insert(log, { "Stop", id, fadeTime })
	end

	function track:Destroy()
		table.insert(log, { "Destroy", id })
	end

	return track
end

-- Stands in for an Animator: LoadAnimation hands back a recording track stub.
local function createAnimatorStub(log)
	local animator = { tracks = {}, loadCount = 0 }

	function animator:LoadAnimation(animation)
		self.loadCount += 1
		local id = animation.AnimationId
		local track = createTrackStub(log, id)
		self.tracks[id] = track
		return track
	end

	return animator
end

local function makeEntry(id)
	return {
		AnimationId = id,
		IsLooped = true,
		Priority = Enum.AnimationPriority.Movement,
	}
end

describe("AnimationTrackPlayer", function()
	local log
	local animator
	local player

	beforeEach(function()
		log = {}
		animator = createAnimatorStub(log)
		player = AnimationTrackPlayer.new(animator)
	end)

	describe("Play", function()
		it("should load the animation and play it with no fade", function()
			player:Play(makeEntry("rbxassetid://1"))

			expect(animator.loadCount).toBe(1)
			expect(log).toEqual({ { "Play", "rbxassetid://1", 0 } })
		end)

		it("should set looping and priority from the entry", function()
			player:Play(makeEntry("rbxassetid://1"))

			local track = animator.tracks["rbxassetid://1"]
			expect(track.Looped).toBe(true)
			expect(track.Priority).toBe(Enum.AnimationPriority.Movement)
		end)

		it("should do nothing when asked for the animation already playing", function()
			player:Play(makeEntry("rbxassetid://1"))
			player:Play(makeEntry("rbxassetid://1"))

			expect(animator.loadCount).toBe(1)
			expect(#log).toBe(1)
		end)

		it("should cut the current track before playing the next, with no fade", function()
			player:Play(makeEntry("rbxassetid://1"))
			player:Play(makeEntry("rbxassetid://2"))

			expect(log).toEqual({
				{ "Play", "rbxassetid://1", 0 },
				{ "Stop", "rbxassetid://1", 0 },
				{ "Play", "rbxassetid://2", 0 },
			})
		end)

		it("should reuse a loaded track when returning to an earlier animation", function()
			player:Play(makeEntry("rbxassetid://1"))
			player:Play(makeEntry("rbxassetid://2"))
			player:Play(makeEntry("rbxassetid://1"))

			expect(animator.loadCount).toBe(2)
		end)
	end)

	describe("Stop", function()
		it("should stop the current track with no fade", function()
			player:Play(makeEntry("rbxassetid://1"))

			player:Stop()

			expect(log[2]).toEqual({ "Stop", "rbxassetid://1", 0 })
		end)

		it("should allow the same animation to be played again afterwards", function()
			player:Play(makeEntry("rbxassetid://1"))
			player:Stop()

			player:Play(makeEntry("rbxassetid://1"))

			expect(log[3]).toEqual({ "Play", "rbxassetid://1", 0 })
		end)

		it("should do nothing when nothing is playing", function()
			expect(function()
				player:Stop()
			end).never.toThrow()
			expect(#log).toBe(0)
		end)
	end)

	describe("Destroy", function()
		it("should stop the current track and destroy every loaded track", function()
			player:Play(makeEntry("rbxassetid://1"))
			player:Play(makeEntry("rbxassetid://2"))
			table.clear(log)

			player:Destroy()

			local destroyed = 0
			for _, call in log do
				if call[1] == "Destroy" then
					destroyed += 1
				end
			end
			expect(destroyed).toBe(2)
			expect(log[1]).toEqual({ "Stop", "rbxassetid://2", 0 })
		end)
	end)
end)
