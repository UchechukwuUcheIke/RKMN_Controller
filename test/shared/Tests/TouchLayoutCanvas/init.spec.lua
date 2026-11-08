--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TouchLayoutCanvas = require(ReplicatedStorage.ControlCustomization.UIComponents.TouchLayoutCanvas)
local TouchGamepadUI = require(ReplicatedStorage.TouchGamepad.UserInterface.TouchGamepadUI)
local MobileButtonPositioner = require(ReplicatedStorage.TouchGamepad.MobileButtonPositioner)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)

local STANDARD = TouchGamepadLayoutRegistry.Standard
local VIEWPORT = Vector2.new(1024, 512)

-- Jump sits in the middle of the screen and is 80 pixels across, so the numbers below stay exact.
local function makeLayout()
	local jump = STANDARD:GetTransform("Jump")
	return STANDARD:CopyWithTransform("Jump", jump:CopyWithChanges({ Position = UDim2.fromScale(0.5, 0.5) }))
end

local function makeCanvas()
	local gamepadUI = TouchGamepadUI.new(Instance.new("Folder"))
	local canvas = TouchLayoutCanvas.new({
		GamepadUI = gamepadUI,
		Positioner = MobileButtonPositioner.new(),
		GetViewportSize = function()
			return VIEWPORT
		end,
		FixedControls = { "Menu" },
	})
	canvas:Render(makeLayout())
	return canvas, gamepadUI
end

local function input(inputType, x, y)
	return { UserInputType = inputType, Position = Vector3.new(x, y, 0) }
end

local function press(canvas, controlID, x, y)
	canvas._handles[controlID].Tracker:_handleInputBegan(input(Enum.UserInputType.MouseButton1, x, y))
end

local function move(canvas, controlID, x, y)
	canvas._handles[controlID].Tracker:_handleInputChanged(input(Enum.UserInputType.MouseMovement, x, y))
end

local function release(canvas, controlID)
	canvas._handles[controlID].Tracker:_handleInputEnded(input(Enum.UserInputType.MouseButton1, 0, 0))
end

local function record(signal)
	local calls = {}
	signal:Connect(function(...)
		table.insert(calls, { ... })
	end)
	return calls
end

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the events are wired to.
describe("TouchLayoutCanvas", function()
	it("draws the layout it is given on the ghost controls", function()
		local _, gamepadUI = makeCanvas()

		expect(gamepadUI:GetButton("Jump"):GetInstance().Position).toEqual(UDim2.fromScale(0.5, 0.5))
	end)

	it("puts a handle over every control", function()
		local canvas = makeCanvas()

		for _, controlID in ipairs(STANDARD:GetControlIDs()) do
			expect(canvas._handles[controlID]).never.toBeNil()
		end
	end)

	it("outlines only the selected control", function()
		local canvas = makeCanvas()

		canvas:SetSelected("Jump")
		expect(canvas._handles.Jump.Outline.Enabled).toBe(true)
		expect(canvas._handles.Dash.Outline.Enabled).toBe(false)

		canvas:SetSelected(nil)
		expect(canvas._handles.Jump.Outline.Enabled).toBe(false)
	end)

	it("announces which control was pressed", function()
		local canvas = makeCanvas()
		local pressed = record(canvas.ControlPressed)

		press(canvas, "Jump", 100, 100)

		expect(pressed).toEqual({ { "Jump" } })
	end)

	it("reports a drag as the control's new position, from how far the pointer has moved", function()
		local canvas = makeCanvas()
		local dragged = record(canvas.ControlDragged)
		press(canvas, "Jump", 100, 100)

		move(canvas, "Jump", 228, 164)

		expect(dragged).toEqual({ { "Jump", UDim2.fromScale(0.625, 0.625) } })
	end)

	it("keeps a dragged control fully on screen", function()
		local canvas = makeCanvas()
		local dragged = record(canvas.ControlDragged)
		press(canvas, "Jump", 100, 100)

		move(canvas, "Jump", 5000, 5000)

		expect(dragged).toEqual({ { "Jump", UDim2.fromScale(0.9609375, 0.921875) } })
	end)

	it("measures every move from where the press began", function()
		local canvas = makeCanvas()
		local dragged = record(canvas.ControlDragged)
		press(canvas, "Jump", 100, 100)

		move(canvas, "Jump", 228, 164)
		move(canvas, "Jump", 100, 100)

		expect(dragged[2]).toEqual({ "Jump", UDim2.fromScale(0.5, 0.5) })
	end)

	it("announces the release", function()
		local canvas = makeCanvas()
		local released = record(canvas.PointerReleased)
		press(canvas, "Jump", 100, 100)

		release(canvas, "Jump")

		expect(#released).toBe(1)
	end)

	it("stops reporting moves once the pointer is released", function()
		local canvas = makeCanvas()
		local dragged = record(canvas.ControlDragged)
		press(canvas, "Jump", 100, 100)
		release(canvas, "Jump")

		move(canvas, "Jump", 228, 164)

		expect(#dragged).toBe(0)
	end)

	it("ignores a second finger on another control until the first lets go", function()
		local canvas = makeCanvas()
		local pressed = record(canvas.ControlPressed)
		local dragged = record(canvas.ControlDragged)
		local released = record(canvas.PointerReleased)
		press(canvas, "Jump", 100, 100)

		press(canvas, "Dash", 300, 300)
		move(canvas, "Dash", 400, 400)
		release(canvas, "Dash")

		expect(pressed).toEqual({ { "Jump" } })
		expect(#dragged).toBe(0)
		expect(#released).toBe(0)

		release(canvas, "Jump")
		expect(#released).toBe(1)

		press(canvas, "Dash", 300, 300)
		expect(#pressed).toBe(2)
	end)

	it("lets a fixed control be pressed but never dragged", function()
		local canvas = makeCanvas()
		local pressed = record(canvas.ControlPressed)
		local dragged = record(canvas.ControlDragged)

		press(canvas, "Menu", 100, 100)
		move(canvas, "Menu", 300, 300)

		expect(pressed).toEqual({ { "Menu" } })
		expect(#dragged).toBe(0)
	end)

	it("ignores moves before the layout has been drawn", function()
		local gamepadUI = TouchGamepadUI.new(Instance.new("Folder"))
		local canvas = TouchLayoutCanvas.new({
			GamepadUI = gamepadUI,
			Positioner = MobileButtonPositioner.new(),
			GetViewportSize = function()
				return VIEWPORT
			end,
			FixedControls = {},
		})
		local dragged = record(canvas.ControlDragged)

		press(canvas, "Jump", 100, 100)
		move(canvas, "Jump", 228, 164)

		expect(#dragged).toBe(0)
	end)

	it("ignores moves while the viewport has no size", function()
		local gamepadUI = TouchGamepadUI.new(Instance.new("Folder"))
		local canvas = TouchLayoutCanvas.new({
			GamepadUI = gamepadUI,
			Positioner = MobileButtonPositioner.new(),
			GetViewportSize = function()
				return Vector2.new()
			end,
			FixedControls = {},
		})
		canvas:Render(makeLayout())
		local dragged = record(canvas.ControlDragged)

		press(canvas, "Jump", 100, 100)
		move(canvas, "Jump", 228, 164)

		expect(#dragged).toBe(0)
	end)
end)
