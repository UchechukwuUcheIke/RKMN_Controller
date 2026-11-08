--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TouchLayoutScreen = require(ReplicatedStorage.ControlCustomization.UIComponents.TouchLayoutScreen)
local TouchLayoutCanvas = require(ReplicatedStorage.ControlCustomization.UIComponents.TouchLayoutCanvas)
local TouchGamepadUI = require(ReplicatedStorage.TouchGamepad.UserInterface.TouchGamepadUI)
local MobileButtonPositioner = require(ReplicatedStorage.TouchGamepad.MobileButtonPositioner)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local UnsavedChangesChoice = require(ReplicatedStorage.ControlCustomization.UIComponents.UnsavedChangesChoice)

local STANDARD = TouchGamepadLayoutRegistry.Standard

local function makeScreen()
	local parent = Instance.new("Folder")
	local gamepadUI = TouchGamepadUI.new(parent)
	local canvas = TouchLayoutCanvas.new({
		GamepadUI = gamepadUI,
		Positioner = MobileButtonPositioner.new(),
		GetViewportSize = function()
			return Vector2.new(1024, 512)
		end,
		FixedControls = { "Menu" },
	})
	local presetOptions = { { Id = "Standard", Name = "Standard" }, { Id = "Compact", Name = "Compact" } }
	local screen = TouchLayoutScreen.new(parent, canvas, presetOptions)
	return screen, { parent = parent, canvas = canvas, gamepadUI = gamepadUI }
end

local function count(signal)
	local total = 0
	signal:Connect(function()
		total += 1
	end)
	return function()
		return total
	end
end

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the events are wired to.
describe("TouchLayoutScreen", function()
	it("stacks a backdrop, the ghost controls and the chrome in that order", function()
		local _, parts = makeScreen()

		local backdrop = parts.parent.TouchLayoutBackdrop.DisplayOrder
		local ghosts = parts.parent.TouchGamepad.DisplayOrder
		local chrome = parts.parent.TouchLayoutChrome.DisplayOrder

		expect(backdrop < ghosts).toBe(true)
		expect(ghosts < chrome).toBe(true)
	end)

	it("starts hidden, and shows and hides every layer", function()
		local screen, parts = makeScreen()
		expect(parts.parent.TouchLayoutChrome.Enabled).toBe(false)

		screen:SetVisible(true)
		expect(parts.parent.TouchLayoutBackdrop.Enabled).toBe(true)
		expect(parts.parent.TouchLayoutChrome.Enabled).toBe(true)
		expect(parts.parent.TouchGamepad.Enabled).toBe(true)

		screen:SetVisible(false)
		expect(parts.parent.TouchGamepad.Enabled).toBe(false)
	end)

	it("draws the layout on the ghost controls", function()
		local screen, parts = makeScreen()

		screen:Render(STANDARD)

		expect(parts.gamepadUI:GetButton("Jump"):GetInstance().Position).toEqual(STANDARD:GetTransform("Jump").Position)
	end)

	it("outlines the selected control and shows its values in the adjustment panel", function()
		local screen, parts = makeScreen()
		screen:Render(STANDARD)

		screen:SetSelection("Jump", STANDARD:GetTransform("Jump"))

		expect(parts.canvas._handles.Jump.Outline.Enabled).toBe(true)
		expect(parts.parent.TouchLayoutChrome.ControlAdjustmentPanel.Title.Text).toBe("Jump")
	end)

	it("clears the outline and the panel when nothing is selected", function()
		local screen, parts = makeScreen()
		screen:Render(STANDARD)
		screen:SetSelection("Jump", STANDARD:GetTransform("Jump"))

		screen:SetSelection(nil, nil)

		expect(parts.canvas._handles.Jump.Outline.Enabled).toBe(false)
		expect(parts.parent.TouchLayoutChrome.ControlAdjustmentPanel.Title.Text).toBe("Select a control")
	end)

	it("switches undo, redo, clear changes and save with the edit state", function()
		local screen = makeScreen()

		expect(screen._undoButton:IsEnabled()).toBe(false)
		expect(screen._saveButton:IsEnabled()).toBe(false)

		screen:SetEditState({ CanUndo = true, CanRedo = false, IsDirty = true })

		expect(screen._undoButton:IsEnabled()).toBe(true)
		expect(screen._redoButton:IsEnabled()).toBe(false)
		expect(screen._discardButton:IsEnabled()).toBe(true)
		expect(screen._saveButton:IsEnabled()).toBe(true)
	end)

	it("keeps exit and presets available whatever the edit state", function()
		local screen = makeScreen()

		expect(screen._exitButton:IsEnabled()).toBe(true)
		expect(screen._presetsButton:IsEnabled()).toBe(true)
	end)

	it("announces each toolbar button when it is pressed", function()
		local screen = makeScreen()
		screen:SetEditState({ CanUndo = true, CanRedo = true, IsDirty = true })
		local exits = count(screen.ExitRequested)
		local undos = count(screen.UndoRequested)
		local redos = count(screen.RedoRequested)
		local discards = count(screen.DiscardRequested)
		local saves = count(screen.SaveRequested)

		screen._exitButton:_handleActivated()
		screen._undoButton:_handleActivated()
		screen._redoButton:_handleActivated()
		screen._discardButton:_handleActivated()
		screen._saveButton:_handleActivated()

		expect({ exits(), undos(), redos(), discards(), saves() }).toEqual({ 1, 1, 1, 1, 1 })
	end)

	it("does not announce a press on a button that is switched off", function()
		local screen = makeScreen()
		local saves = count(screen.SaveRequested)

		screen._saveButton:_handleActivated()

		expect(saves()).toBe(0)
	end)

	it("announces a press on the backdrop, so the editor can clear the selection", function()
		local screen = makeScreen()
		local presses = count(screen.BackgroundPressed)

		screen:_handleBackdropActivated()

		expect(presses()).toBe(1)
	end)

	it("keeps the unsaved-changes prompt hidden until asked", function()
		local screen, parts = makeScreen()
		local prompt = parts.parent.TouchLayoutChrome.UnsavedChangesPrompt
		expect(prompt.Visible).toBe(false)

		screen:ShowUnsavedChangesPrompt()
		expect(prompt.Visible).toBe(true)

		screen:HideUnsavedChangesPrompt()
		expect(prompt.Visible).toBe(false)
	end)

	it("passes the prompt's choice on", function()
		local screen = makeScreen()
		local choices = {}
		screen.UnsavedChoiceMade:Connect(function(choice)
			table.insert(choices, choice)
		end)

		screen._unsavedPrompt._buttons[2]:_handleActivated()

		expect(choices).toEqual({ UnsavedChangesChoice.Discard })
	end)

	it("opens the preset picker when Presets is pressed", function()
		local screen, parts = makeScreen()
		local picker = parts.parent.TouchLayoutChrome.PresetPicker
		expect(picker.Visible).toBe(false)

		screen._presetsButton:_handleActivated()

		expect(picker.Visible).toBe(true)
	end)

	it("closes the picker and announces the preset that was chosen", function()
		local screen, parts = makeScreen()
		local chosen = {}
		screen.PresetChosen:Connect(function(presetID)
			table.insert(chosen, presetID)
		end)
		screen._presetsButton:_handleActivated()

		screen._presetPicker._optionButtons[2]:_handleActivated()

		expect(chosen).toEqual({ "Compact" })
		expect(parts.parent.TouchLayoutChrome.PresetPicker.Visible).toBe(false)
	end)

	it("closes the picker without choosing anything when it is cancelled", function()
		local screen, parts = makeScreen()
		local chosen = 0
		screen.PresetChosen:Connect(function()
			chosen += 1
		end)
		screen._presetsButton:_handleActivated()

		screen._presetPicker._cancelButton:_handleActivated()

		expect(chosen).toBe(0)
		expect(parts.parent.TouchLayoutChrome.PresetPicker.Visible).toBe(false)
	end)

	it("puts away the picker and the unsaved-changes prompt when the screen is hidden", function()
		local screen, parts = makeScreen()
		screen:SetVisible(true)
		screen._presetsButton:_handleActivated()
		screen:ShowUnsavedChangesPrompt()

		screen:SetVisible(false)

		expect(parts.parent.TouchLayoutChrome.PresetPicker.Visible).toBe(false)
		expect(parts.parent.TouchLayoutChrome.UnsavedChangesPrompt.Visible).toBe(false)
	end)

	it("passes the adjustment panel's events on", function()
		local screen = makeScreen()
		local scaleChanges = {}
		screen.ScaleChanged:Connect(function(scale)
			table.insert(scaleChanges, scale)
		end)
		screen._adjustmentPanel:ShowControl("Jump", 1, 0.5)

		screen._adjustmentPanel._sizeSlider:_setValueFromFraction(1)

		expect(scaleChanges).toEqual({ 1.5 })
	end)
end)
