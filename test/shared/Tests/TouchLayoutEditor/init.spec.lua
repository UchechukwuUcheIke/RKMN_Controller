--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local TouchLayoutEditor = require(ReplicatedStorage.ControlCustomization.TouchLayoutEditor)
local TouchLayoutProfile = require(ReplicatedStorage.TouchGamepad.TouchLayoutProfile)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local UnsavedChangesChoice = require(ReplicatedStorage.ControlCustomization.UIComponents.UnsavedChangesChoice)

local STANDARD = TouchGamepadLayoutRegistry.Standard
local MOVED = UDim2.fromScale(0.4, 0.4)

-- Moves Jump and Menu, so a test can see Jump follow the preset while the fixed Menu stays put.
local function makePreset()
	local jump = STANDARD:GetTransform("Jump")
	local menu = STANDARD:GetTransform("Menu")
	local layout = STANDARD:CopyWithTransform("Jump", jump:CopyWithChanges({ Position = MOVED }))
	layout = layout:CopyWithTransform("Menu", menu:CopyWithChanges({ Position = UDim2.fromScale(0.1, 0.1) }))
	return { Id = "Test", Name = "Test", Layout = layout }
end

local function makeFakeScreen()
	local screen = {
		ExitRequested = Signal.new(),
		UndoRequested = Signal.new(),
		RedoRequested = Signal.new(),
		DiscardRequested = Signal.new(),
		PresetChosen = Signal.new(),
		SaveRequested = Signal.new(),
		BackgroundPressed = Signal.new(),
		UnsavedChoiceMade = Signal.new(),
		ScaleChanged = Signal.new(),
		TransparencyChanged = Signal.new(),
		AdjustmentStarted = Signal.new(),
		AdjustmentEnded = Signal.new(),
		isVisible = false,
		isPromptShown = false,
		layout = nil,
		selectedControl = nil,
		selectedTransform = nil,
		editState = nil,
	}
	function screen:Render(layout)
		self.layout = layout
	end
	function screen:SetSelection(controlID, transform)
		self.selectedControl = controlID
		self.selectedTransform = transform
	end
	function screen:SetEditState(editState)
		self.editState = editState
	end
	function screen:SetVisible(isVisible)
		self.isVisible = isVisible
	end
	function screen:ShowUnsavedChangesPrompt()
		self.isPromptShown = true
	end
	function screen:HideUnsavedChangesPrompt()
		self.isPromptShown = false
	end
	return screen
end

local function makeFakeCanvas()
	return {
		ControlPressed = Signal.new(),
		ControlDragged = Signal.new(),
		PointerReleased = Signal.new(),
	}
end

local function makeFakePlayerInput()
	local playerInput = { OnMenuPressed = Signal.new(), calls = {} }
	for _, methodName in ipairs({ "SuspendGameplayInput", "ResumeGameplayInput" }) do
		playerInput[methodName] = function(self)
			table.insert(self.calls, methodName)
		end
	end
	return playerInput
end

local function makeFakeTouchGamepad()
	local touchGamepad = { calls = {} }
	for _, methodName in ipairs({ "Suspend", "Resume" }) do
		touchGamepad[methodName] = function(self)
			table.insert(self.calls, methodName)
		end
	end
	return touchGamepad
end

local function makeEditor(startingDevice)
	local detector = { device = startingDevice or "touch", OnContextChanged = Signal.new() }
	function detector:GetCurrentDevice()
		return self.device
	end

	local parts = {
		detector = detector,
		profile = TouchLayoutProfile.new(STANDARD),
		playerInput = makeFakePlayerInput(),
		touchGamepad = makeFakeTouchGamepad(),
		canvas = makeFakeCanvas(),
		screen = makeFakeScreen(),
	}
	local editor = TouchLayoutEditor.new({
		DeviceDetector = detector,
		LayoutProfile = parts.profile,
		PlayerInput = parts.playerInput,
		TouchGamepad = parts.touchGamepad,
		Canvas = parts.canvas,
		Screen = parts.screen,
		Presets = { makePreset() },
		FixedControls = { "Menu" },
	})
	editor:Enable()
	return editor, parts
end

local function makeOpenEditor()
	local editor, parts = makeEditor()
	parts.playerInput.OnMenuPressed:Fire()
	return editor, parts
end

local function count(list, name)
	local total = 0
	for _, entry in ipairs(list) do
		if entry == name then
			total += 1
		end
	end
	return total
end

local function jump(parts)
	return parts.screen.layout:GetTransform("Jump")
end

local function dragJump(parts, position)
	parts.canvas.ControlPressed:Fire("Jump")
	parts.canvas.ControlDragged:Fire("Jump", position)
	parts.canvas.PointerReleased:Fire()
end

describe("TouchLayoutEditor", function()
	describe("opening and closing", function()
		it("opens when the menu is pressed on a touch device, taking over the screen", function()
			local editor, parts = makeOpenEditor()

			expect(editor:IsOpen()).toBe(true)
			expect(parts.screen.isVisible).toBe(true)
			expect(parts.screen.layout).toBe(STANDARD)
			expect(parts.touchGamepad.calls).toEqual({ "Suspend" })
			expect(parts.playerInput.calls).toEqual({ "SuspendGameplayInput" })
		end)

		it("stays closed when the menu is pressed on another device", function()
			local editor, parts = makeEditor("keyboard")

			parts.playerInput.OnMenuPressed:Fire()

			expect(editor:IsOpen()).toBe(false)
			expect(parts.screen.isVisible).toBe(false)
		end)

		it("does nothing when the menu is pressed again while open", function()
			local _, parts = makeOpenEditor()

			parts.playerInput.OnMenuPressed:Fire()

			expect(count(parts.touchGamepad.calls, "Suspend")).toBe(1)
		end)

		it("closes through Exit when nothing has changed, handing the screen back", function()
			local editor, parts = makeOpenEditor()

			parts.screen.ExitRequested:Fire()

			expect(editor:IsOpen()).toBe(false)
			expect(parts.screen.isVisible).toBe(false)
			expect(parts.touchGamepad.calls).toEqual({ "Suspend", "Resume" })
			expect(parts.playerInput.calls).toEqual({ "SuspendGameplayInput", "ResumeGameplayInput" })
		end)

		it("closes when the device stops being touch", function()
			local editor, parts = makeOpenEditor()

			parts.detector.OnContextChanged:Fire("keyboard")

			expect(editor:IsOpen()).toBe(false)
			expect(count(parts.playerInput.calls, "ResumeGameplayInput")).toBe(1)
		end)

		it("closes when disabled, and no longer reacts to the menu", function()
			local editor, parts = makeOpenEditor()

			editor:Disable()
			parts.playerInput.OnMenuPressed:Fire()

			expect(editor:IsOpen()).toBe(false)
			expect(count(parts.playerInput.calls, "SuspendGameplayInput")).toBe(1)
		end)
	end)

	describe("editing", function()
		it("selects a control when it is pressed and shows its values", function()
			local _, parts = makeOpenEditor()

			parts.canvas.ControlPressed:Fire("Jump")
			parts.canvas.PointerReleased:Fire()

			expect(parts.screen.selectedControl).toBe("Jump")
			expect(parts.screen.selectedTransform).toBe(STANDARD:GetTransform("Jump"))
		end)

		it("moves a control as it is dragged", function()
			local _, parts = makeOpenEditor()

			parts.canvas.ControlPressed:Fire("Jump")
			parts.canvas.ControlDragged:Fire("Jump", MOVED)

			expect(jump(parts).Position).toEqual(MOVED)
		end)

		it("makes a whole drag one undo step", function()
			local _, parts = makeOpenEditor()

			parts.canvas.ControlPressed:Fire("Jump")
			parts.canvas.ControlDragged:Fire("Jump", UDim2.fromScale(0.3, 0.3))
			parts.canvas.ControlDragged:Fire("Jump", MOVED)
			parts.canvas.PointerReleased:Fire()
			expect(parts.screen.editState).toEqual({ CanUndo = true, CanRedo = false, IsDirty = true })

			parts.screen.UndoRequested:Fire()

			expect(jump(parts).Position).toEqual(STANDARD:GetTransform("Jump").Position)
			expect(parts.screen.editState.CanUndo).toBe(false)
		end)

		it("ignores a drag that no press started", function()
			local _, parts = makeOpenEditor()

			parts.canvas.ControlDragged:Fire("Jump", MOVED)

			expect(jump(parts).Position).toEqual(STANDARD:GetTransform("Jump").Position)
		end)

		it("changes the selected control's size and opacity from the sliders", function()
			local _, parts = makeOpenEditor()
			dragJump(parts, STANDARD:GetTransform("Jump").Position)

			parts.screen.AdjustmentStarted:Fire()
			parts.screen.ScaleChanged:Fire(1.25)
			parts.screen.TransparencyChanged:Fire(0.25)
			parts.screen.AdjustmentEnded:Fire()

			expect(jump(parts).Scale).toBe(1.25)
			expect(jump(parts).Transparency).toBe(0.25)
		end)

		it("makes a slider pull one undo step", function()
			local _, parts = makeOpenEditor()
			dragJump(parts, STANDARD:GetTransform("Jump").Position)

			parts.screen.AdjustmentStarted:Fire()
			parts.screen.ScaleChanged:Fire(1.1)
			parts.screen.ScaleChanged:Fire(1.25)
			parts.screen.AdjustmentEnded:Fire()
			parts.screen.UndoRequested:Fire()

			expect(jump(parts).Scale).toBe(1)
		end)

		it("ignores a slider change when nothing is selected", function()
			local _, parts = makeOpenEditor()

			parts.screen.AdjustmentStarted:Fire()
			parts.screen.ScaleChanged:Fire(1.25)
			parts.screen.AdjustmentEnded:Fire()

			expect(parts.screen.editState.IsDirty).toBe(false)
		end)

		it("ignores the sliders while a control is being dragged, and a press while a slider is being pulled", function()
			local _, parts = makeOpenEditor()
			dragJump(parts, STANDARD:GetTransform("Jump").Position)

			parts.canvas.ControlPressed:Fire("Dash")
			parts.screen.ScaleChanged:Fire(1.25)
			expect(jump(parts).Scale).toBe(1)
			expect(parts.screen.selectedControl).toBe("Dash")
			parts.canvas.PointerReleased:Fire()

			parts.canvas.ControlPressed:Fire("Jump")
			parts.canvas.PointerReleased:Fire()
			parts.screen.AdjustmentStarted:Fire()
			parts.canvas.ControlPressed:Fire("Dash")
			expect(parts.screen.selectedControl).toBe("Jump")
			parts.screen.AdjustmentEnded:Fire()
		end)

		it("clears the selection when the backdrop is pressed", function()
			local _, parts = makeOpenEditor()
			dragJump(parts, STANDARD:GetTransform("Jump").Position)

			parts.screen.BackgroundPressed:Fire()

			expect(parts.screen.selectedControl).toBeNil()
		end)

		it("redoes what was undone", function()
			local _, parts = makeOpenEditor()
			dragJump(parts, MOVED)
			parts.screen.UndoRequested:Fire()

			parts.screen.RedoRequested:Fire()

			expect(jump(parts).Position).toEqual(MOVED)
		end)

		it("throws away unsaved edits when asked to clear changes", function()
			local _, parts = makeOpenEditor()
			dragJump(parts, MOVED)

			parts.screen.DiscardRequested:Fire()

			expect(jump(parts).Position).toEqual(STANDARD:GetTransform("Jump").Position)
			expect(parts.screen.editState.IsDirty).toBe(false)
		end)
	end)

	describe("presets", function()
		it("applies a chosen preset to the draft", function()
			local _, parts = makeOpenEditor()

			parts.screen.PresetChosen:Fire("Test")

			expect(jump(parts).Position).toEqual(MOVED)
			expect(parts.screen.editState.IsDirty).toBe(true)
		end)

		it("leaves a control the player cannot move where it was", function()
			local _, parts = makeOpenEditor()

			parts.screen.PresetChosen:Fire("Test")

			expect(parts.screen.layout:GetTransform("Menu")).toBe(STANDARD:GetTransform("Menu"))
		end)

		it("is one undo step", function()
			local _, parts = makeOpenEditor()
			parts.screen.PresetChosen:Fire("Test")

			parts.screen.UndoRequested:Fire()

			expect(jump(parts).Position).toEqual(STANDARD:GetTransform("Jump").Position)
		end)

		it("ignores a preset it does not know", function()
			local _, parts = makeOpenEditor()

			parts.screen.PresetChosen:Fire("Nope")

			expect(parts.screen.editState.IsDirty).toBe(false)
		end)

		it("does not touch the saved layout until Save", function()
			local _, parts = makeOpenEditor()

			parts.screen.PresetChosen:Fire("Test")

			expect(parts.profile:GetLayout()).toBe(STANDARD)
		end)
	end)

	describe("saving", function()
		it("writes the draft to the profile and stays open", function()
			local editor, parts = makeOpenEditor()
			dragJump(parts, MOVED)

			parts.screen.SaveRequested:Fire()

			expect(parts.profile:GetLayout():GetTransform("Jump").Position).toEqual(MOVED)
			expect(parts.screen.editState.IsDirty).toBe(false)
			expect(editor:IsOpen()).toBe(true)
		end)

		it("does not touch the profile until saved", function()
			local _, parts = makeOpenEditor()

			dragJump(parts, MOVED)

			expect(parts.profile:GetLayout()).toBe(STANDARD)
		end)

		it("asks before exiting with unsaved changes, and stays open", function()
			local editor, parts = makeOpenEditor()
			dragJump(parts, MOVED)

			parts.screen.ExitRequested:Fire()

			expect(parts.screen.isPromptShown).toBe(true)
			expect(editor:IsOpen()).toBe(true)
		end)

		it("saves and closes when the prompt is answered Save", function()
			local editor, parts = makeOpenEditor()
			dragJump(parts, MOVED)
			parts.screen.ExitRequested:Fire()

			parts.screen.UnsavedChoiceMade:Fire(UnsavedChangesChoice.Save)

			expect(parts.profile:GetLayout():GetTransform("Jump").Position).toEqual(MOVED)
			expect(editor:IsOpen()).toBe(false)
			expect(parts.screen.isPromptShown).toBe(false)
		end)

		it("closes without saving when the prompt is answered Discard", function()
			local editor, parts = makeOpenEditor()
			dragJump(parts, MOVED)
			parts.screen.ExitRequested:Fire()

			parts.screen.UnsavedChoiceMade:Fire(UnsavedChangesChoice.Discard)

			expect(parts.profile:GetLayout()).toBe(STANDARD)
			expect(editor:IsOpen()).toBe(false)
		end)

		it("stays open with the edits when the prompt is answered Cancel", function()
			local editor, parts = makeOpenEditor()
			dragJump(parts, MOVED)
			parts.screen.ExitRequested:Fire()

			parts.screen.UnsavedChoiceMade:Fire(UnsavedChangesChoice.Cancel)

			expect(editor:IsOpen()).toBe(true)
			expect(parts.screen.isPromptShown).toBe(false)
			expect(jump(parts).Position).toEqual(MOVED)
		end)

		it("starts the next visit from the saved layout, with no leftover edits", function()
			local editor, parts = makeOpenEditor()
			dragJump(parts, MOVED)
			parts.screen.SaveRequested:Fire()
			parts.screen.ExitRequested:Fire()

			parts.playerInput.OnMenuPressed:Fire()

			expect(editor:IsOpen()).toBe(true)
			expect(jump(parts).Position).toEqual(MOVED)
			expect(parts.screen.editState).toEqual({ CanUndo = false, CanRedo = false, IsDirty = false })
		end)
	end)
end)
