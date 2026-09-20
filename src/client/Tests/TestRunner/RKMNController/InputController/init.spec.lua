local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = require(
	ReplicatedStorage
		:WaitForChild("RKMNController")
		:WaitForChild("InputController")
)

local KEY_BINDINGS = require(
	ReplicatedStorage
		:WaitForChild("RKMNController")
		:WaitForChild("KeyBindings")
)

local TIMERS = require(
	ReplicatedStorage
		:WaitForChild("RKMNController")
		:WaitForChild("TimerIDRegistry")
)

return function()
	-- Minimal fake TimerUtility so these tests do not depend on the real timer implementation.
	local function createMockTimer()
		local Timer = {
			StartedTimers = {},
			CancelledTimers = {},
			CompletedTimers = {},
		}

		function Timer:StartTimer(timerId, duration)
			self.StartedTimers[timerId] = duration
		end

		function Timer:Cancel(timerId)
			self.CancelledTimers[timerId] = true
		end

		function Timer.IsCompleted(timerId)
			return Timer.CompletedTimers[timerId] == true
		end

		return Timer
	end

	local Controller: InputController.InputController = nil
	local Timer

	beforeEach(function()
		Timer = createMockTimer()
		Controller = InputController.new(Timer)
	end)

	afterEach(function()
        -- TODO: Antipattern, we need a clean way to determine whether a class is destroyed
		if not table.isfrozen(Controller) then
			Controller:Destroy()
		end
	end)

	describe("InputController Instantiation", function()
		it("creates a disabled controller by default", function()
			expect(Controller.IsEnabled).to.equal(false)
		end)

		it("stores the provided TimerUtility", function()
			expect(Controller.Timer).to.equal(Timer)
		end)

		it("initializes movement and input state", function()
			expect(Controller.MoveDirection).to.equal(0)
			expect(Controller.IsHoldingJump).to.equal(false)
			expect(Controller.IsHoldingDash).to.equal(false)
			expect(Controller.IsCharging).to.equal(false)
			expect(Controller.HasBufferedJump).to.equal(false)
		end)

		it("starts with no event connections", function()
			expect(#Controller._connections).to.equal(0)
		end)

		it("creates all expected signals", function()
			expect(Controller.OnJumpPressed).never.to.equal(nil)
			expect(Controller.OnDashPressed).never.to.equal(nil)
			expect(Controller.OnShootBegan).never.to.equal(nil)
			expect(Controller.OnShootEnded).never.to.equal(nil)
		end)
	end)

	describe("SetEnabled", function()
		it("enables the controller when passed true", function()
			Controller:SetEnabled(true)

			expect(Controller.IsEnabled).to.equal(true)
		end)

		it("disables the controller when passed false", function()
			Controller:SetEnabled(true)
			Controller:SetEnabled(false)

			expect(Controller.IsEnabled).to.equal(false)
		end)

		it("flushes active input state when disabled", function()
			Controller.IsHoldingJump = true
			Controller.IsHoldingDash = true
			Controller.IsCharging = true
			Controller.MoveDirection = 1
			Controller.HasBufferedJump = true

			Controller:SetEnabled(false)

			expect(Controller.IsHoldingJump).to.equal(false)
			expect(Controller.IsHoldingDash).to.equal(false)
			expect(Controller.IsCharging).to.equal(false)
			expect(Controller.MoveDirection).to.equal(0)
			expect(Controller.HasBufferedJump).to.equal(false)
		end)

		it("does not flush state when remaining enabled", function()
			Controller.IsHoldingJump = true
			Controller.IsHoldingDash = true
			Controller.IsCharging = true
			Controller.MoveDirection = 1
			Controller.HasBufferedJump = true

			Controller:SetEnabled(true)

			expect(Controller.IsHoldingJump).to.equal(true)
			expect(Controller.IsHoldingDash).to.equal(true)
			expect(Controller.IsCharging).to.equal(true)
			expect(Controller.MoveDirection).to.equal(1)
			expect(Controller.HasBufferedJump).to.equal(true)
		end)
	end)

	describe("ConsumeJumpBuffer", function()
		it("clears the buffered jump", function()
			Controller.HasBufferedJump = true

			Controller:ConsumeJumpBuffer()

			expect(Controller.HasBufferedJump).to.equal(false)
		end)

		it("cancels the jump buffer timer", function()
			Controller:ConsumeJumpBuffer()

			expect(Timer.CancelledTimers[TIMERS.JumpBuffer]).to.equal(true)
		end)
	end)

	describe("FlushActiveInputs", function()
		it("resets movement direction", function()
			Controller.MoveDirection = -1

			Controller:FlushActiveInputs()

			expect(Controller.MoveDirection).to.equal(0)
		end)

		it("clears all held-input state", function()
			Controller.IsHoldingJump = true
			Controller.IsHoldingDash = true
			Controller.IsCharging = true

			Controller:FlushActiveInputs()

			expect(Controller.IsHoldingJump).to.equal(false)
			expect(Controller.IsHoldingDash).to.equal(false)
			expect(Controller.IsCharging).to.equal(false)
		end)

		it("consumes the jump buffer", function()
			Controller.HasBufferedJump = true

			Controller:FlushActiveInputs()

			expect(Controller.HasBufferedJump).to.equal(false)
			expect(Timer.CancelledTimers[TIMERS.JumpBuffer]).to.equal(true)
		end)
	end)

	describe("_handleJumpInput", function()
		it("fires OnJumpPressed", function()
			local callCount = 0

			Controller.OnJumpPressed:Connect(function()
				callCount += 1
			end)

			-- This test intentionally exercises the actual implementation.
			-- It currently errors because the class references self.Timers
			-- instead of self.Timer.
			Controller:_handleJumpInput()

			expect(callCount).to.equal(1)
		end)

		it("sets HasBufferedJump", function()
			Controller:_handleJumpInput()

			expect(Controller.HasBufferedJump).to.equal(true)
		end)

		it("starts the jump buffer timer", function()
			Controller:_handleJumpInput()

			expect(Timer.StartedTimers[TIMERS.JumpBuffer]).to.equal(0.1)
		end)
	end)

	describe("Poll", function()
		it("does nothing while disabled", function()
			Controller.IsEnabled = false
			Controller.MoveDirection = 1
			Controller.IsHoldingJump = true
			Controller.IsHoldingDash = true
			Controller.IsCharging = true

			Controller:Poll(1 / 60)

			expect(Controller.MoveDirection).to.equal(1)
			expect(Controller.IsHoldingJump).to.equal(true)
			expect(Controller.IsHoldingDash).to.equal(true)
			expect(Controller.IsCharging).to.equal(true)
		end)

		it("clears a completed jump buffer", function()
			Controller.IsEnabled = true
			Controller.HasBufferedJump = true
			Timer.CompletedTimers[TIMERS.JumpBuffer] = true

			Controller:Poll(1 / 60)

			expect(Controller.HasBufferedJump).to.equal(false)
		end)

		it("keeps a jump buffer while its timer is incomplete", function()
			Controller.IsEnabled = true
			Controller.HasBufferedJump = true
			Timer.CompletedTimers[TIMERS.JumpBuffer] = false

			Controller:Poll(1 / 60)

			expect(Controller.HasBufferedJump).to.equal(true)
		end)
	end)

	describe("_resolveMoveDirection", function()
		-- NOTE:
		-- _resolveMoveDirection uses shared("KeyBindings") and
		-- UserInputService:IsKeyDown(), so these tests require a way
		-- to mock UserInputService in your test environment.
		--
		-- The intended cases are:
		--
		-- neither held  -> 0
		-- left only     -> -1
		-- right only    -> 1
		-- both held     -> 0
	end)

	describe("_onInputBegan", function()
		local function fakeInput(keyCode)
			return {
				KeyCode = keyCode,
			} :: any
		end

		it("ignores input when gameProcessed is true", function()
			Controller.IsEnabled = true

			local jumpCount = 0

			Controller.OnJumpPressed:Connect(function()
				jumpCount += 1
			end)

			Controller:_onInputBegan(
				fakeInput(KEY_BINDINGS.Jump[1]),
				true
			)

			expect(jumpCount).to.equal(0)
		end)

		it("ignores input when the controller is disabled", function()
			Controller.IsEnabled = false

			local jumpCount = 0

			Controller.OnJumpPressed:Connect(function()
				jumpCount += 1
			end)

			Controller:_onInputBegan(
				fakeInput(KEY_BINDINGS.Jump[1]),
				false
			)

			expect(jumpCount).to.equal(0)
		end)

		it("fires OnJumpPressed for a jump binding when enabled", function()
			Controller.IsEnabled = true

			local jumpCount = 0

			Controller.OnJumpPressed:Connect(function()
				jumpCount += 1
			end)

			Controller:_onInputBegan(
				fakeInput(KEY_BINDINGS.Jump[1]),
				false
			)

			expect(jumpCount).to.equal(1)
		end)

		it("fires OnDashPressed for a dash binding", function()
			Controller.IsEnabled = true

			local dashCount = 0

			Controller.OnDashPressed:Connect(function()
				dashCount += 1
			end)

			Controller:_onInputBegan(
				fakeInput(KEY_BINDINGS.Dash[1]),
				false
			)

			expect(dashCount).to.equal(1)
		end)

		it("fires OnShootBegan for a shoot binding", function()
			Controller.IsEnabled = true

			local shootCount = 0

			Controller.OnShootBegan:Connect(function()
				shootCount += 1
			end)

			Controller:_onInputBegan(
				fakeInput(KEY_BINDINGS.Shoot[1]),
				false
			)

			expect(shootCount).to.equal(1)
		end)
	end)

	describe("_onInputEnded", function()
		local function fakeInput(keyCode)
			return {
				KeyCode = keyCode,
			} :: any
		end

		it("fires OnShootEnded for a shoot binding", function()
			local shootEndCount = 0

			Controller.OnShootEnded:Connect(function()
				shootEndCount += 1
			end)

			Controller:_onInputEnded(
				fakeInput(KEY_BINDINGS.Shoot[1]),
				false
			)

			expect(shootEndCount).to.equal(1)
		end)

		it("does not fire OnShootEnded for a jump binding", function()
			local shootEndCount = 0

			Controller.OnShootEnded:Connect(function()
				shootEndCount += 1
			end)

			Controller:_onInputEnded(
				fakeInput(KEY_BINDINGS.Jump[1]),
				false
			)

			expect(shootEndCount).to.equal(0)
		end)
	end)

	describe("_bindEvents", function()
		it("creates two input connections", function()
			-- This currently exposes a bug in _bindEvents:
			-- it calls self._onInputEnd, but the implemented method is
			-- self._onInputEnded.
			Controller:_bindEvents()

			expect(#Controller._connections).to.equal(2)
		end)
	end)

	describe("Destroy", function()
		it("disconnects all stored connections", function()
			-- Populate _connections with fake connection objects so this
			-- test does not depend on UserInputService.
			local disconnected = 0

			table.insert(Controller._connections, {
				Disconnect = function()
					disconnected += 1
				end,
			} :: any)

			table.insert(Controller._connections, {
				Disconnect = function()
					disconnected += 1
				end,
			} :: any)

			Controller:Destroy()

			expect(disconnected).to.equal(2)
			expect(Controller._connections).to.equal(nil)
		end)
	end)
end