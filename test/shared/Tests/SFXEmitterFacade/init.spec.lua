--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local SFXEmitterFacade = require(ReplicatedStorage.SFXEmitter.SFXEmitterFacade)

describe("SFXEmitterFacade", function()
	local parent
	local emitter

	beforeEach(function()
		parent = Instance.new("Folder")
		-- An empty SoundId means nothing is actually played, so these tests make no audio.
		emitter = SFXEmitterFacade.new({
			Parent = parent,
			Registry = { Jump = { SoundId = "", Volume = 1, PlaybackSpeed = 1 } },
		})
	end)

	afterEach(function()
		parent:Destroy()
	end)

	describe("new", function()
		it("should create an SFX folder under the given parent", function()
			local folder = parent:FindFirstChild("SFX")

			expect(folder).toBeDefined()
			expect(folder:IsA("Folder")).toBe(true)
		end)

		it("should keep one Sound ready in that folder, grouped under the SFX SoundGroup", function()
			local folder = parent.SFX
			local sound = folder:FindFirstChildOfClass("Sound")

			expect(sound).toBeDefined()
			expect(sound.SoundGroup).toBe(folder.SFXGroup)
		end)
	end)

	describe("Play", function()
		it("should not error for a known id with no sound yet, or an unknown id", function()
			expect(function()
				emitter:Play("Jump")
				emitter:Play("Missing")
			end).never.toThrow()
		end)
	end)

	describe("Bind", function()
		it("should return a connection and not error when the signal fires", function()
			local signal = Signal.new()
			local connection = emitter:Bind(signal, "Jump", function()
				return true
			end)

			expect(connection).toBeDefined()
			expect(function()
				signal:Fire()
			end).never.toThrow()
		end)
	end)

	describe("SetVolume and SetMuted", function()
		it("should drive the SFX SoundGroup", function()
			local group = parent.SFX.SFXGroup

			emitter:SetVolume(0.25)
			expect(group.Volume).toBeCloseTo(0.25)

			emitter:SetMuted(true)
			expect(group.Volume).toBe(0)
		end)
	end)

	describe("Destroy", function()
		it("should remove the SFX folder", function()
			emitter:Destroy()

			expect(parent:FindFirstChild("SFX")).toBeNil()
		end)

		it("should stop reacting to bound signals", function()
			local signal = Signal.new()
			local calls = 0
			emitter:Bind(signal, "Jump", function()
				calls += 1
				return false
			end)

			emitter:Destroy()
			signal:Fire()

			expect(calls).toBe(0)
		end)
	end)
end)
