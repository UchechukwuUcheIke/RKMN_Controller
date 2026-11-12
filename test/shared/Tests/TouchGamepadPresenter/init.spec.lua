--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local TouchGamepadPresenter = require(ReplicatedStorage.TouchGamepad.TouchGamepadPresenter)
local TouchGamepadUI = require(ReplicatedStorage.TouchGamepad.UserInterface.TouchGamepadUI)
local MobileButtonPositioner = require(ReplicatedStorage.TouchGamepad.MobileButtonPositioner)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)
local TouchLayoutProfile = require(ReplicatedStorage.TouchGamepad.TouchLayoutProfile)

local STANDARD = TouchGamepadLayoutRegistry.Standard

local function makeFakeDetector(startingDevice)
	local detector = { device = startingDevice, OnContextChanged = Signal.new() }
	function detector:GetCurrentDevice()
		return self.device
	end
	function detector:Switch(device)
		self.device = device
		self.OnContextChanged:Fire(device)
	end
	return detector
end

local function makeFakePlayerInput()
	local playerInput = { boundCount = 0 }
	function playerInput:BindVirtualButton()
		self.boundCount += 1
	end
	function playerInput:ReleaseVirtualHolds() end
	return playerInput
end

local function makePresenter(startingDevice)
	local detector = makeFakeDetector(startingDevice)
	local playerInput = makeFakePlayerInput()
	local gamepadUI = TouchGamepadUI.new(Instance.new("Folder"))
	local profile = TouchLayoutProfile.new(STANDARD)
	local presenter = TouchGamepadPresenter.new(detector, playerInput, gamepadUI, MobileButtonPositioner.new(), profile)
	return presenter, { detector = detector, playerInput = playerInput, gamepadUI = gamepadUI, profile = profile }
end

local function jumpPosition(parts)
	return parts.gamepadUI:GetButton("Jump"):GetInstance().Position
end

local function movedJumpLayout()
	local jump = STANDARD:GetTransform("Jump")
	return STANDARD:CopyWithTransform("Jump", jump:CopyWithChanges({ Position = UDim2.fromScale(0.5, 0.5) }))
end

describe("TouchGamepadPresenter", function()
	it("places the controls from the profile's layout once on a touch device", function()
		local presenter, parts = makePresenter("touch")

		presenter:Enable()

		expect(jumpPosition(parts)).toEqual(STANDARD:GetTransform("Jump").Position)
		presenter:Destroy()
	end)

	it("leaves the controls unbound until the device is touch", function()
		local presenter, parts = makePresenter("keyboard")

		presenter:Enable()

		expect(parts.playerInput.boundCount).toBe(0)
		presenter:Destroy()
	end)

	it("moves the controls when the profile's layout changes", function()
		local presenter, parts = makePresenter("touch")
		presenter:Enable()

		parts.profile:SetLayout(movedJumpLayout())

		expect(jumpPosition(parts)).toEqual(UDim2.fromScale(0.5, 0.5))
		presenter:Destroy()
	end)

	it("uses the layout current at the time the device first becomes touch", function()
		local presenter, parts = makePresenter("keyboard")
		presenter:Enable()
		parts.profile:SetLayout(movedJumpLayout())

		parts.detector:Switch("touch")

		expect(jumpPosition(parts)).toEqual(UDim2.fromScale(0.5, 0.5))
		presenter:Destroy()
	end)

	it("stops following the profile once disabled", function()
		local presenter, parts = makePresenter("touch")
		presenter:Enable()
		presenter:Disable()

		parts.profile:SetLayout(movedJumpLayout())

		expect(jumpPosition(parts)).toEqual(STANDARD:GetTransform("Jump").Position)
		presenter:Destroy()
	end)

	it("hides the controls while suspended, without bringing Roblox's controls back", function()
		local presenter, parts = makePresenter("touch")
		presenter:Enable()

		presenter:Suspend()

		expect(parts.gamepadUI._screenGui.Enabled).toBe(false)
		expect(GuiService.TouchControlsEnabled).toBe(false)
		presenter:Destroy()
	end)

	it("stays hidden while suspended even when the device becomes touch", function()
		local presenter, parts = makePresenter("keyboard")
		presenter:Enable()
		presenter:Suspend()

		parts.detector:Switch("touch")

		expect(parts.gamepadUI._screenGui.Enabled).toBe(false)
		presenter:Destroy()
	end)

	it("shows the controls again, in the profile's current layout, when resumed on a touch device", function()
		local presenter, parts = makePresenter("touch")
		presenter:Enable()
		presenter:Suspend()
		parts.profile:SetLayout(movedJumpLayout())

		presenter:Resume()

		expect(parts.gamepadUI._screenGui.Enabled).toBe(true)
		expect(jumpPosition(parts)).toEqual(UDim2.fromScale(0.5, 0.5))
		presenter:Destroy()
	end)

	it("does not show the controls on resume when the presenter is disabled", function()
		local presenter, parts = makePresenter("touch")
		presenter:Enable()
		presenter:Suspend()
		presenter:Disable()

		presenter:Resume()

		expect(parts.gamepadUI._screenGui.Enabled).toBe(false)
		presenter:Destroy()
	end)

	it("turns Roblox's built-in touch controls off while enabled and back on when disabled", function()
		local presenter = makePresenter("touch")

		presenter:Enable()
		expect(GuiService.TouchControlsEnabled).toBe(false)

		presenter:Disable()
		expect(GuiService.TouchControlsEnabled).toBe(true)
		presenter:Destroy()
	end)
end)
