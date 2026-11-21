--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local SFXPlayer = require(ReplicatedStorage.SFXEmitter.SFXPlayer)

-- Stands in for a Sound: records Play and lets the test finish it by firing Ended.
local function createSoundStub()
	local sound = { Ended = Signal.new(), playCount = 0 }

	function sound.Ended:Once(handler)
		local connection
		connection = self:Connect(function(...)
			connection:Disconnect()
			handler(...)
		end)
		return connection
	end

	function sound:Play()
		self.playCount += 1
	end

	return sound
end

-- Stands in for SoundObjectPool.
local function createPoolStub()
	local pool = { acquired = {}, released = {} }

	function pool:Acquire()
		local sound = createSoundStub()
		table.insert(self.acquired, sound)
		return sound
	end

	function pool:Release(sound)
		table.insert(self.released, sound)
	end

	return pool
end

describe("SFXPlayer", function()
	local registry
	local pool
	local dashPool
	local player

	beforeEach(function()
		registry = {
			Jump = { SoundId = "rbxassetid://jump", Volume = 0.5, PlaybackSpeed = 1.5 },
			Dash = { SoundId = "", Volume = 1, PlaybackSpeed = 1 },
		}
		pool = createPoolStub()
		dashPool = createPoolStub()
		player = SFXPlayer.new(registry, { Jump = pool, Dash = dashPool })
	end)

	describe("Play", function()
		it("should play a sound from that id's pool without reconfiguring it", function()
			player:Play("Jump")

			local sound = pool.acquired[1]
			expect(sound.SoundId).toBeNil()
			expect(sound.playCount).toBe(1)
		end)

		it("should skip an id that is not in the registry", function()
			player:Play("Missing")

			expect(#pool.acquired).toBe(0)
		end)

		it("should skip an entry whose SoundId is still empty", function()
			player:Play("Dash")

			expect(#dashPool.acquired).toBe(0)
		end)

		it("should return the sound to the pool when it ends", function()
			player:Play("Jump")
			local sound = pool.acquired[1]

			expect(#pool.released).toBe(0)
			sound.Ended:Fire()

			expect(pool.released[1]).toBe(sound)
		end)

		it("should use separate sounds for overlapping plays", function()
			player:Play("Jump")
			player:Play("Jump")

			expect(#pool.acquired).toBe(2)
			expect(pool.acquired[1]).never.toBe(pool.acquired[2])
		end)
	end)
end)
