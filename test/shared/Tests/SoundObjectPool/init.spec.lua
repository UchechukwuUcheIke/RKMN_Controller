--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local SoundObjectPool = require(ReplicatedStorage.SFXEmitter.SoundObjectPool)

describe("SoundObjectPool", function()
	local created
	local destroyed

	local function createSound()
		local sound = { destroyed = false }
		function sound:Destroy()
			self.destroyed = true
			table.insert(destroyed, self)
		end
		table.insert(created, sound)
		return sound
	end

	beforeEach(function()
		created = {}
		destroyed = {}
	end)

	describe("new", function()
		it("should keep one sound ready by default", function()
			SoundObjectPool.new(createSound)

			expect(#created).toBe(1)
		end)

		it("should keep the requested number of sounds ready", function()
			SoundObjectPool.new(createSound, 3)

			expect(#created).toBe(3)
		end)
	end)

	describe("Acquire", function()
		it("should hand out the ready sound without creating another", function()
			local pool = SoundObjectPool.new(createSound)

			local sound = pool:Acquire()

			expect(sound).toBe(created[1])
			expect(#created).toBe(1)
		end)

		it("should create a new sound when every sound is in use", function()
			local pool = SoundObjectPool.new(createSound)

			local first = pool:Acquire()
			local second = pool:Acquire()

			expect(second).never.toBe(first)
			expect(#created).toBe(2)
		end)
	end)

	describe("Release", function()
		it("should make a released sound available again", function()
			local pool = SoundObjectPool.new(createSound)
			local sound = pool:Acquire()

			pool:Release(sound)

			expect(pool:Acquire()).toBe(sound)
			expect(#created).toBe(1)
		end)

		it("should not hand the same sound out twice after a double release", function()
			local pool = SoundObjectPool.new(createSound)
			local sound = pool:Acquire()

			pool:Release(sound)
			pool:Release(sound)

			local first = pool:Acquire()
			local second = pool:Acquire()
			expect(second).never.toBe(first)
		end)

		it("should ignore a sound the pool did not create", function()
			local pool = SoundObjectPool.new(createSound)

			pool:Release({})

			pool:Acquire()
			expect(#created).toBe(1)
			local extra = pool:Acquire()
			expect(extra).toBe(created[2])
		end)
	end)

	describe("Destroy", function()
		it("should destroy every sound it created, in use or not", function()
			local pool = SoundObjectPool.new(createSound)
			pool:Acquire()
			pool:Acquire()

			pool:Destroy()

			expect(#destroyed).toBe(2)
		end)
	end)
end)
