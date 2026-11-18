--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local SFXBinder = require(ReplicatedStorage.SFXEmitter.SFXBinder)

-- Stands in for SFXPlayer: records which ids were played.
local function createPlayerStub()
	local player = { played = {} }

	function player:Play(sfxId)
		table.insert(self.played, sfxId)
	end

	return player
end

describe("SFXBinder", function()
	local player
	local binder
	local signal

	beforeEach(function()
		player = createPlayerStub()
		binder = SFXBinder.new(player)
		signal = Signal.new()
	end)

	describe("Bind", function()
		it("should play the sound every time the signal fires when there is no condition", function()
			binder:Bind(signal, "Pickup")

			signal:Fire()
			signal:Fire()

			expect(player.played).toEqual({ "Pickup", "Pickup" })
		end)

		it("should pass the signal's arguments to the condition", function()
			local received
			binder:Bind(signal, "Jump", function(...)
				received = { ... }
				return true
			end)

			signal:Fire("Jump", "WallSlide")

			expect(received).toEqual({ "Jump", "WallSlide" })
		end)

		it("should play only when the condition returns true", function()
			binder:Bind(signal, "WallJump", function(newId, previousId)
				return newId == "Jump" and previousId == "WallSlide"
			end)

			signal:Fire("Jump", "Idle")
			expect(#player.played).toBe(0)

			signal:Fire("Jump", "WallSlide")
			expect(player.played).toEqual({ "WallJump" })
		end)

		it("should let one signal drive several sounds independently", function()
			binder:Bind(signal, "A", function(id) return id == "a" end)
			binder:Bind(signal, "B", function(id) return id == "b" end)

			signal:Fire("b")

			expect(player.played).toEqual({ "B" })
		end)

		it("should return a connection that stops that binding", function()
			local connection = binder:Bind(signal, "Pickup")

			connection:Disconnect()
			signal:Fire()

			expect(#player.played).toBe(0)
		end)
	end)

	describe("Destroy", function()
		it("should stop every binding", function()
			binder:Bind(signal, "A")
			binder:Bind(signal, "B")

			binder:Destroy()
			signal:Fire()

			expect(#player.played).toBe(0)
		end)
	end)
end)
