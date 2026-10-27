--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TimerUtility = require(ReplicatedStorage.RKMNController.TimerUtility)
local InputBuffer = require(ReplicatedStorage.PlayerInput.InputBuffer)

local function makeBuffer()
	local timer = TimerUtility.new()
	return InputBuffer.new(timer, "TestBuffer", 0.1), timer
end

describe("InputBuffer", function()
	it("is empty until filled", function()
		local buffer = makeBuffer()
		expect(buffer:IsFilled()).toBe(false)
	end)

	it("is filled after Fill", function()
		local buffer = makeBuffer()
		buffer:Fill()
		expect(buffer:IsFilled()).toBe(true)
	end)

	it("empties once the window has passed, without any extra update", function()
		local buffer, timer = makeBuffer()
		buffer:Fill()
		timer:Step(0.2)
		expect(buffer:IsFilled()).toBe(false)
	end)

	it("restarts the window when filled again", function()
		local buffer, timer = makeBuffer()
		buffer:Fill()
		timer:Step(0.08)
		buffer:Fill()
		timer:Step(0.08)
		expect(buffer:IsFilled()).toBe(true)
	end)

	it("reports whether Consume found a buffered input", function()
		local buffer = makeBuffer()
		expect(buffer:Consume()).toBe(false)

		buffer:Fill()
		expect(buffer:Consume()).toBe(true)
		expect(buffer:IsFilled()).toBe(false)
		expect(buffer:Consume()).toBe(false)
	end)

	it("cancels its timer when destroyed", function()
		local buffer, timer = makeBuffer()
		buffer:Fill()
		buffer:Destroy()
		expect(timer:IsComplete("TestBuffer")).toBe(true)
	end)
end)
