--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local ControlProfile = require(ReplicatedStorage.PlayerInput.ControlProfile)
local KeyboardSchemes = require(ReplicatedStorage.PlayerInput.KeyboardSchemes)
local GamepadSchemes = require(ReplicatedStorage.PlayerInput.GamepadSchemes)
local BindingCapture = require(ReplicatedStorage.PlayerInput.BindingCapture)
local ControlCustomizationUI = require(ReplicatedStorage.ControlCustomization.ControlCustomizationUI)

-- Stands in for UserInputService, whose input events can't be driven from a test.
local function makeFakeInputService()
	local service = { InputBegan = Signal.new() }
	function service:Press(inputType, keyCode, gameProcessed)
		self.InputBegan:Fire({ UserInputType = inputType, KeyCode = keyCode or Enum.KeyCode.Unknown }, gameProcessed or false)
	end
	return service
end

local function makeFakePlayerInput()
	local playerInput = { OnMenuPressed = Signal.new(), calls = {} }
	for _, methodName in ipairs({ "SuspendGameplayInput", "ResumeGameplayInput", "DisableMenuKey", "EnableMenuKey" }) do
		playerInput[methodName] = function(self)
			table.insert(self.calls, methodName)
		end
	end
	return playerInput
end

local function makeFakeBindingsScreen()
	local screen = {
		OnRebindRequested = Signal.new(),
		OnUnbindRequested = Signal.new(),
		OnResetRequested = Signal.new(),
		OnExitRequested = Signal.new(),
		isVisible = nil,
		rendered = nil,
		capturingAction = nil,
	}
	function screen:SetVisible(isVisible)
		self.isVisible = isVisible
	end
	function screen:Render(device)
		self.rendered = device
	end
	function screen:SetCapturing(actionName)
		self.capturingAction = actionName
	end
	return screen
end

local function makeMenu()
	local profile = ControlProfile.new(KeyboardSchemes.Standard, GamepadSchemes.Standard)
	local inputService = makeFakeInputService()
	local capture = BindingCapture.new(inputService)
	local playerInput = makeFakePlayerInput()
	local screen = makeFakeBindingsScreen()
	local view = { isVisible = false }
	function view:GetBindingsScreen()
		return screen
	end
	function view:SetVisible(isVisible)
		self.isVisible = isVisible
	end
	function view:Destroy() end

	local detector = { device = "keyboard", OnContextChanged = Signal.new() }
	function detector:GetCurrentDevice()
		return self.device
	end

	-- Stands in for the next frame: callbacks wait here until the test says a frame has passed.
	local pending = {}
	local function runNextFrame(callback)
		table.insert(pending, callback)
	end
	local function advanceFrame()
		local callbacks = pending
		pending = {}
		for _, callback in ipairs(callbacks) do
			callback()
		end
	end

	local menu = ControlCustomizationUI.new(detector, profile, playerInput, capture, view, runNextFrame)
	menu:Enable()

	return menu, {
		profile = profile,
		inputService = inputService,
		capture = capture,
		playerInput = playerInput,
		screen = screen,
		view = view,
		detector = detector,
		advanceFrame = advanceFrame,
	}
end

local function countCalls(playerInput, methodName)
	local count = 0
	for _, name in ipairs(playerInput.calls) do
		if name == methodName then
			count += 1
		end
	end
	return count
end

describe("ControlCustomizationUI", function()
	it("opens on a menu press, suspending gameplay input", function()
		local menu, parts = makeMenu()

		parts.playerInput.OnMenuPressed:Fire()

		expect(menu:IsOpen()).toBe(true)
		expect(parts.view.isVisible).toBe(true)
		expect(countCalls(parts.playerInput, "SuspendGameplayInput")).toBe(1)
		expect(parts.screen.rendered).toBe("keyboard")
	end)

	it("closes on a second menu press, resuming gameplay input", function()
		local menu, parts = makeMenu()

		parts.playerInput.OnMenuPressed:Fire()
		parts.playerInput.OnMenuPressed:Fire()

		expect(menu:IsOpen()).toBe(false)
		expect(parts.view.isVisible).toBe(false)
		expect(countCalls(parts.playerInput, "ResumeGameplayInput")).toBe(1)
	end)

	it("disables the menu key while waiting for a binding", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()

		parts.screen.OnRebindRequested:Fire(InputAction.Jump)

		expect(parts.capture:IsCapturing()).toBe(true)
		expect(countCalls(parts.playerInput, "DisableMenuKey")).toBe(1)
		expect(parts.screen.capturingAction).toBe(InputAction.Jump)
	end)

	it("binds the pressed key, and re-enables the menu key only on the next frame", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()
		parts.screen.OnRebindRequested:Fire(InputAction.Jump)

		parts.inputService:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)

		expect(parts.profile:GetScheme("keyboard")[InputAction.Jump][Enum.KeyCode.J]).toBe(true)
		expect(parts.screen.capturingAction).toBe(nil)
		expect(countCalls(parts.playerInput, "EnableMenuKey")).toBe(0)

		parts.advanceFrame()

		expect(countCalls(parts.playerInput, "EnableMenuKey")).toBe(1)
	end)

	it("leaves the bindings alone when the capture is cancelled", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()
		local before = parts.profile:GetScheme("keyboard")
		parts.screen.OnRebindRequested:Fire(InputAction.Jump)

		parts.inputService:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.Escape)
		parts.advanceFrame()

		expect(parts.profile:GetScheme("keyboard")).toBe(before)
		expect(countCalls(parts.playerInput, "EnableMenuKey")).toBe(1)
	end)

	it("keeps the menu key disabled when a second rebind starts before the first one's frame passes", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()
		parts.screen.OnRebindRequested:Fire(InputAction.Jump)
		parts.inputService:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)

		parts.screen.OnRebindRequested:Fire(InputAction.Dash)
		parts.advanceFrame()

		expect(countCalls(parts.playerInput, "EnableMenuKey")).toBe(0)
	end)

	it("cancels a capture in progress when the menu is closed", function()
		local menu, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()
		parts.screen.OnRebindRequested:Fire(InputAction.Jump)

		menu:Close()
		parts.advanceFrame()

		expect(parts.capture:IsCapturing()).toBe(false)
		expect(countCalls(parts.playerInput, "EnableMenuKey")).toBe(1)
	end)

	it("cancels a capture in progress when the device changes", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()
		parts.screen.OnRebindRequested:Fire(InputAction.Jump)

		parts.detector.device = "gamepad"
		parts.detector.OnContextChanged:Fire("gamepad")

		expect(parts.capture:IsCapturing()).toBe(false)
		expect(parts.screen.rendered).toBe("gamepad")
	end)

	it("resets the device in use when asked", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()
		parts.screen.OnRebindRequested:Fire(InputAction.Jump)
		parts.inputService:Press(Enum.UserInputType.Keyboard, Enum.KeyCode.J)

		parts.screen.OnResetRequested:Fire()

		expect(parts.profile:GetScheme("keyboard")).toBe(KeyboardSchemes.Standard)
	end)

	it("removes a binding from the device in use when asked", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()

		parts.screen.OnUnbindRequested:Fire(InputAction.Jump, Enum.KeyCode.Space)

		expect(parts.profile:GetScheme("keyboard")[InputAction.Jump][Enum.KeyCode.Space]).toBeNil()
	end)

	it("closes and gives gameplay input back when exit is pressed", function()
		local menu, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()

		parts.screen.OnExitRequested:Fire()

		expect(menu:IsOpen()).toBe(false)
		expect(parts.view.isVisible).toBe(false)
		expect(countCalls(parts.playerInput, "ResumeGameplayInput")).toBe(1)
	end)

	it("does not open on a touch device, which has its own editor", function()
		local menu, parts = makeMenu()
		parts.detector.device = "touch"

		parts.playerInput.OnMenuPressed:Fire()

		expect(menu:IsOpen()).toBe(false)
		expect(parts.view.isVisible).toBe(false)
		expect(countCalls(parts.playerInput, "SuspendGameplayInput")).toBe(0)
	end)

	it("refuses rebinds when the device turns to touch while open", function()
		local _, parts = makeMenu()
		parts.playerInput.OnMenuPressed:Fire()
		parts.detector.device = "touch"
		parts.detector.OnContextChanged:Fire("touch")

		parts.screen.OnRebindRequested:Fire(InputAction.Jump)

		expect(parts.screen.isVisible).toBe(false)
		expect(parts.capture:IsCapturing()).toBe(false)
		expect(countCalls(parts.playerInput, "DisableMenuKey")).toBe(0)
	end)

	it("stops reacting once disabled", function()
		local menu, parts = makeMenu()

		menu:Disable()
		parts.playerInput.OnMenuPressed:Fire()

		expect(menu:IsOpen()).toBe(false)
	end)
end)
