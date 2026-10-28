--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Direction = require(ReplicatedStorage.Data.Direction)
local TimerUtility = require(ReplicatedStorage.RKMNController.TimerUtility)
local InputMapper = require(ReplicatedStorage.PlayerInput.InputMapper)
local KeyboardSchemes = require(ReplicatedStorage.PlayerInput.KeyboardSchemes)
local PlayerInputFacade = require(ReplicatedStorage.PlayerInput.PlayerInputFacade)

-- Real keyboard state can't be driven from a test, so actions are fed through the observer's signals.
local function makeFacade()
	local timer = TimerUtility.new()
	local mapper = InputMapper.new()
	mapper:LoadControlScheme(KeyboardSchemes.Standard)
	local facade = PlayerInputFacade.new(timer, mapper)

	local events = { jump = 0, dash = 0, pressed = 0, released = 0 }
	facade.OnJumpPressed:Connect(function() events.jump += 1 end)
	facade.OnDashPressed:Connect(function() events.dash += 1 end)
	facade.OnTriggerPressed:Connect(function() events.pressed += 1 end)
	facade.OnTriggerReleased:Connect(function() events.released += 1 end)

	local function press(action)
		facade._rawInputObserver.OnActionBegan:Fire(action)
	end
	local function release(action)
		facade._rawInputObserver.OnActionEnded:Fire(action)
	end

	return facade, timer, events, press, release
end

describe("PlayerInputFacade", function()
	it("ignores input until enabled", function()
		local facade, _, events, press = makeFacade()

		press("Jump")
		press("Dash")
		press("Shoot")

		expect(events).toEqual({ jump = 0, dash = 0, pressed = 0, released = 0 })
		expect(facade:HasBufferedJump()).toBe(false)
	end)

	it("buffers and announces a jump press", function()
		local facade, _, events, press = makeFacade()
		facade:SetEnabled(true)

		press("Jump")

		expect(events.jump).toBe(1)
		expect(facade:HasBufferedJump()).toBe(true)
		expect(facade:HasBufferedDash()).toBe(false)
	end)

	it("lets a buffered jump expire and be consumed", function()
		local facade, timer, _, press = makeFacade()
		facade:SetEnabled(true)

		press("Jump")
		timer:Step(0.2)
		expect(facade:HasBufferedJump()).toBe(false)

		press("Dash")
		facade:ConsumeDashBuffer()
		expect(facade:HasBufferedDash()).toBe(false)
	end)

	it("reports trigger presses and releases", function()
		local facade, _, events, press, release = makeFacade()
		facade:SetEnabled(true)

		press("Shoot")
		release("Shoot")

		expect(events.pressed).toBe(1)
		expect(events.released).toBe(1)
	end)

	it("releases a held trigger when disabled", function()
		local facade, _, events, press = makeFacade()
		facade:SetEnabled(true)

		press("Shoot")
		facade:SetEnabled(false)

		expect(events.released).toBe(1)
	end)

	it("does not report a release for a press it never saw", function()
		local facade, _, events, press, release = makeFacade()

		press("Shoot")
		facade:SetEnabled(true)
		release("Shoot")

		expect(events.released).toBe(0)
	end)

	it("reports a single release when disabling after the trigger was already released", function()
		local facade, _, events, press, release = makeFacade()
		facade:SetEnabled(true)

		press("Shoot")
		release("Shoot")
		facade:SetEnabled(false)

		expect(events.released).toBe(1)
	end)

	it("clears buffers, direction and held state when disabled", function()
		local facade, _, _, press = makeFacade()
		facade:SetEnabled(true)
		press("Jump")
		press("Dash")

		facade:SetEnabled(false)

		expect(facade:HasBufferedJump()).toBe(false)
		expect(facade:HasBufferedDash()).toBe(false)
		expect(facade:GetMoveDirection()).toBe(Direction.None)
		expect(facade:IsHoldingJump()).toBe(false)
		expect(facade:IsCharging()).toBe(false)
	end)

	it("stops reacting once destroyed", function()
		local facade, _, events = makeFacade()
		facade:SetEnabled(true)
		local observer = facade._rawInputObserver

		facade:Destroy()
		observer.OnActionBegan:Fire("Jump")

		expect(events.jump).toBe(0)
	end)
end)
