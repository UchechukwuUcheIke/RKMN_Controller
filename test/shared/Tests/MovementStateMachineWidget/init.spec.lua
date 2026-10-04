--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DebugModuleFolder = RKMNControllerFolder.DebugModule
local WidgetsFolder = DebugModuleFolder.Widgets
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local MovementStateMachineWidget = require(WidgetsFolder.MovementStateMachineWidget)
local MockWorld = require(ReplicatedStorage.MockWorld.MockWorld)
local MockerUtils = require(ReplicatedStorage.TestUtils.MockUtils)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local WIDGET_CANVAS_NAME = "MovementStateMachineWidget"
local CURRENT_KEY = "Current State"
local PREVIOUS_KEY = "Previous State"

local function makeStateMachineMock(currentStateId, previousStateId)
	return MockerUtils.createMockClass(MovementStateMachine, {
		CurrentStateId = currentStateId,
		Context = {
			PreviousStateId = previousStateId,
		},
	})
end

local function makeStateMachine(currentStateId, previousStateId)
	return makeStateMachineMock(currentStateId, previousStateId).Instance
end

local function expectNoStateMachineMethodsCalled(stateMachineMock)
	for _, mockFn in stateMachineMock.Mocks do
		expect(mockFn).never.toHaveBeenCalled()
	end
end

local function getWidgetCanvas(gui: Instance): Frame?
	return gui:FindFirstChild(WIDGET_CANVAS_NAME) :: Frame?
end

local function getRowCanvas(gui: Instance, rowKey: string): Frame?
	local widgetCanvas = getWidgetCanvas(gui)
	if not widgetCanvas then
		return nil
	end
	return widgetCanvas:FindFirstChild("DataRow_" .. rowKey) :: Frame?
end

local function getRowLabel(gui: Instance, rowKey: string, labelName: string): TextLabel?
	local rowCanvas = getRowCanvas(gui, rowKey)
	if not rowCanvas then
		return nil
	end
	return rowCanvas:FindFirstChild(labelName) :: TextLabel?
end

local function getCurrentStateText(gui: Instance): string
	return getRowLabel(gui, CURRENT_KEY, "ValueLabel").Text
end

local function getPreviousStateText(gui: Instance): string
	return getRowLabel(gui, PREVIOUS_KEY, "ValueLabel").Text
end

describe("MovementStateMachineWidget", function()
	local mockWorld
	local part: Part
	local surfaceGui: SurfaceGui
	local stateMachineMock
	local stateMachine
	local widget

	beforeEach(function()
		mockWorld = MockWorld.new()
		part = mockWorld:SpawnPart()

		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Parent = part

		stateMachineMock = makeStateMachineMock("Idle", nil)
		stateMachine = stateMachineMock.Instance
		widget = MovementStateMachineWidget.new(stateMachine)
	end)

	afterEach(function()
		-- Destroy() strips the metatable, so guard against destroying a widget twice
		if widget and getmetatable(widget) ~= nil then
			widget:Destroy()
		end
		widget = nil
		stateMachine = nil
		stateMachineMock = nil
		mockWorld:Destroy()
		mockWorld = nil
	end)

	describe("new", function()
		it("returns a table", function()
			expect(typeof(widget)).toBe("table")
		end)

		it("uses MovementStateMachineWidget as its metatable", function()
			expect(getmetatable(widget)).toBe(MovementStateMachineWidget)
		end)

		it("starts unmounted", function()
			expect(widget.IsMounted).toBe(false)
		end)

		it("does not call any methods on the state machine", function()
			expectNoStateMachineMethodsCalled(stateMachineMock)
		end)

		it("does not parent anything to the SurfaceGui on creation", function()
			expect(#surfaceGui:GetChildren()).toBe(0)
		end)

		it("does not throw for a different state machine", function()
			expect(function()
				local other = MovementStateMachineWidget.new(makeStateMachine("Running", "Idle"))
				other:Destroy()
			end).never.toThrow()
		end)

		it("creates independent instances", function()
			local other = MovementStateMachineWidget.new(makeStateMachine("Running", "Idle"))
			widget:MountTo(surfaceGui)

			expect(widget.IsMounted).toBe(true)
			expect(other.IsMounted).toBe(false)
			expect(#surfaceGui:GetChildren()).toBe(1)

			other:Destroy()
		end)
	end)

	describe("UI structure", function()
		local canvas: Frame

		beforeEach(function()
			widget:MountTo(surfaceGui)
			canvas = getWidgetCanvas(surfaceGui)
		end)

		it("creates a Frame canvas named MovementStateMachineWidget", function()
			expect(canvas).toBeDefined()
			expect(canvas:IsA("Frame")).toBe(true)
			expect(canvas.Name).toBe("MovementStateMachineWidget")
		end)

		it("makes the canvas background transparent", function()
			expect(canvas.BackgroundTransparency).toBe(1)
		end)

		it("contains a UIListLayout and two data rows", function()
			expect(#canvas:GetChildren()).toBe(3)
			expect(canvas:FindFirstChildOfClass("UIListLayout")).toBeDefined()
			expect(getRowCanvas(surfaceGui, CURRENT_KEY)).toBeDefined()
			expect(getRowCanvas(surfaceGui, PREVIOUS_KEY)).toBeDefined()
		end)

		describe("list layout", function()
			local listLayout: UIListLayout

			beforeEach(function()
				listLayout = canvas:FindFirstChildOfClass("UIListLayout")
			end)

			it("sorts by LayoutOrder", function()
				expect(listLayout.SortOrder).toBe(Enum.SortOrder.LayoutOrder)
			end)

			it("fills vertically", function()
				expect(listLayout.FillDirection).toBe(Enum.FillDirection.Vertical)
			end)

			it("fills horizontally and does not flex vertically", function()
				expect(listLayout.HorizontalFlex).toBe(Enum.UIFlexAlignment.Fill)
				expect(listLayout.VerticalFlex).toBe(Enum.UIFlexAlignment.None)
			end)
		end)

		describe("data rows", function()
			it("labels the first row 'Current State'", function()
				expect(getRowLabel(surfaceGui, CURRENT_KEY, "KeyLabel").Text).toBe("Current State")
			end)

			it("labels the second row 'Previous State'", function()
				expect(getRowLabel(surfaceGui, PREVIOUS_KEY, "KeyLabel").Text).toBe("Previous State")
			end)

			it("parents both rows to the widget canvas", function()
				expect(getRowCanvas(surfaceGui, CURRENT_KEY).Parent).toBe(canvas)
				expect(getRowCanvas(surfaceGui, PREVIOUS_KEY).Parent).toBe(canvas)
			end)

			it("starts both values as 'None'", function()
				expect(getCurrentStateText(surfaceGui)).toBe("None")
				expect(getPreviousStateText(surfaceGui)).toBe("None")
			end)

			it("does not show the state machine's state until Render is called", function()
				-- stateMachine.CurrentStateId is "Idle", but nothing has rendered yet
				expect(getCurrentStateText(surfaceGui)).never.toBe("Idle")
			end)
		end)
	end)

	describe("MountTo", function()
		it("parents the widget canvas to the SurfaceGui", function()
			widget:MountTo(surfaceGui)

			local canvas = getWidgetCanvas(surfaceGui)
			expect(canvas).toBeDefined()
			expect(canvas.Parent).toBe(surfaceGui)
		end)

		it("sets IsMounted to true", function()
			widget:MountTo(surfaceGui)
			expect(widget.IsMounted).toBe(true)
		end)

		it("makes the widget and its rows descendants of the spawned part", function()
			widget:MountTo(surfaceGui)

			expect(getWidgetCanvas(surfaceGui):IsDescendantOf(part)).toBe(true)
			expect(getRowCanvas(surfaceGui, CURRENT_KEY):IsDescendantOf(part)).toBe(true)
			expect(getRowCanvas(surfaceGui, PREVIOUS_KEY):IsDescendantOf(part)).toBe(true)
		end)

		it("can move the widget to a different layer collector", function()
			local otherGui = Instance.new("SurfaceGui")
			otherGui.Parent = part

			widget:MountTo(surfaceGui)
			widget:MountTo(otherGui)

			expect(getWidgetCanvas(surfaceGui)).toBeNil()
			expect(getWidgetCanvas(otherGui)).toBeDefined()
			expect(widget.IsMounted).toBe(true)

			otherGui:Destroy()
		end)

		it("can be mounted to a non-GUI parent", function()
			local folder = Instance.new("Folder")
			widget:MountTo(folder)

			expect(getWidgetCanvas(folder)).toBeDefined()
			expect(widget.IsMounted).toBe(true)

			folder:Destroy()
		end)

		it("supports multiple widgets under one SurfaceGui", function()
			local second = MovementStateMachineWidget.new(makeStateMachine("Running", "Idle"))
			widget:MountTo(surfaceGui)
			second:MountTo(surfaceGui)

			expect(#surfaceGui:GetChildren()).toBe(2)

			second:Destroy()
		end)

		it("preserves rendered values across a remount", function()
			widget:MountTo(surfaceGui)
			stateMachine.CurrentStateId = "Running"
			widget:Render()

			local otherGui = Instance.new("SurfaceGui")
			otherGui.Parent = part
			widget:MountTo(otherGui)

			expect(getCurrentStateText(otherGui)).toBe("Running")

			otherGui:Destroy()
		end)
	end)

	describe("Render", function()
		beforeEach(function()
			widget:MountTo(surfaceGui)
		end)

		it("shows the current state id", function()
			widget:Render()
			expect(getCurrentStateText(surfaceGui)).toBe("Idle")
		end)

		it("shows 'None' for the previous state when it is nil", function()
			widget:Render()
			expect(getPreviousStateText(surfaceGui)).toBe("None")
		end)

		it("shows the previous state id when one is set", function()
			stateMachine.Context.PreviousStateId = "Walking"
			widget:Render()
			expect(getPreviousStateText(surfaceGui)).toBe("Walking")
		end)

		it("converts numeric state ids to strings", function()
			stateMachine.CurrentStateId = 3
			stateMachine.Context.PreviousStateId = 2
			widget:Render()

			expect(getCurrentStateText(surfaceGui)).toBe("3")
			expect(getPreviousStateText(surfaceGui)).toBe("2")
		end)

		it("keeps the numeric id 0 instead of treating it as missing", function()
			-- 0 is truthy in Luau, so `PreviousStateId or "None"` should keep it
			stateMachine.Context.PreviousStateId = 0
			widget:Render()
			expect(getPreviousStateText(surfaceGui)).toBe("0")
		end)

		it("picks up state changes on the next Render", function()
			widget:Render()
			expect(getCurrentStateText(surfaceGui)).toBe("Idle")

			stateMachine.Context.PreviousStateId = stateMachine.CurrentStateId
			stateMachine.CurrentStateId = "Running"
			widget:Render()

			expect(getCurrentStateText(surfaceGui)).toBe("Running")
			expect(getPreviousStateText(surfaceGui)).toBe("Idle")
		end)

		it("does not update until Render is called again", function()
			widget:Render()
			stateMachine.CurrentStateId = "Running"

			expect(getCurrentStateText(surfaceGui)).toBe("Idle")
		end)

		it("resets the previous state to 'None' when it becomes nil", function()
			stateMachine.Context.PreviousStateId = "Walking"
			widget:Render()
			expect(getPreviousStateText(surfaceGui)).toBe("Walking")

			stateMachine.Context.PreviousStateId = nil
			widget:Render()
			expect(getPreviousStateText(surfaceGui)).toBe("None")
		end)

		it("is idempotent", function()
			widget:Render()
			widget:Render()
			widget:Render()

			expect(getCurrentStateText(surfaceGui)).toBe("Idle")
			expect(getPreviousStateText(surfaceGui)).toBe("None")
		end)

		it("does not change the key labels", function()
			widget:Render()

			expect(getRowLabel(surfaceGui, CURRENT_KEY, "KeyLabel").Text).toBe("Current State")
			expect(getRowLabel(surfaceGui, PREVIOUS_KEY, "KeyLabel").Text).toBe("Previous State")
		end)

		it("does not modify the state machine", function()
			stateMachine.Context.PreviousStateId = "Walking"
			widget:Render()

			expect(stateMachine.CurrentStateId).toBe("Idle")
			expect(stateMachine.Context.PreviousStateId).toBe("Walking")
		end)

		it("does not call any methods on the state machine", function()
			widget:Render()
			expectNoStateMachineMethodsCalled(stateMachineMock)
		end)

		it("only updates its own widget", function()
			local otherGui = Instance.new("SurfaceGui")
			otherGui.Parent = part
			local otherMachine = makeStateMachine("Jumping", "Idle")
			local other = MovementStateMachineWidget.new(otherMachine)
			other:MountTo(otherGui)

			widget:Render()

			expect(getCurrentStateText(surfaceGui)).toBe("Idle")
			expect(getCurrentStateText(otherGui)).toBe("None")

			other:Render()
			expect(getCurrentStateText(otherGui)).toBe("Jumping")
			expect(getPreviousStateText(otherGui)).toBe("Idle")

			other:Destroy()
			otherGui:Destroy()
		end)

		it("does not throw before the widget is mounted", function()
			local unmounted = MovementStateMachineWidget.new(makeStateMachine("Idle", nil))

			expect(function()
				unmounted:Render()
			end).never.toThrow()

			unmounted:Destroy()
		end)
	end)

	describe("Destroy", function()
		it("destroys the widget canvas", function()
			widget:MountTo(surfaceGui)
			local canvas = getWidgetCanvas(surfaceGui)

			local destroyed = false
			canvas.Destroying:Connect(function()
				destroyed = true
			end)

			widget:Destroy()

			expect(destroyed).toBe(true)
			expect(canvas.Parent).toBeNil()
		end)

		it("removes the widget from the SurfaceGui", function()
			widget:MountTo(surfaceGui)
			widget:Destroy()

			expect(getWidgetCanvas(surfaceGui)).toBeNil()
			expect(#surfaceGui:GetChildren()).toBe(0)
		end)

		it("destroys both data rows", function()
			widget:MountTo(surfaceGui)
			local currentRow = getRowCanvas(surfaceGui, CURRENT_KEY)
			local previousRow = getRowCanvas(surfaceGui, PREVIOUS_KEY)

			local destroyedCount = 0
			currentRow.Destroying:Connect(function()
				destroyedCount += 1
			end)
			previousRow.Destroying:Connect(function()
				destroyedCount += 1
			end)

			widget:Destroy()

			expect(destroyedCount).toBe(2)
			expect(currentRow.Parent).toBeNil()
			expect(previousRow.Parent).toBeNil()
		end)

		it("does not throw when the widget was never mounted", function()
			expect(function()
				widget:Destroy()
			end).never.toThrow()
		end)

		it("does not destroy or modify the state machine", function()
			stateMachine.Context.PreviousStateId = "Walking"
			widget:MountTo(surfaceGui)
			widget:Destroy()

			expect(stateMachine.CurrentStateId).toBe("Idle")
			expect(stateMachine.Context.PreviousStateId).toBe("Walking")
		end)

		it("does not call any methods on the state machine, including Destroy", function()
			widget:MountTo(surfaceGui)
			widget:Render()
			widget:Destroy()

			expectNoStateMachineMethodsCalled(stateMachineMock)
		end)

		it("removes the metatable", function()
			widget:Destroy()
			expect(getmetatable(widget)).toBeNil()
		end)

		it("freezes the instance table", function()
			widget:Destroy()
			expect(table.isfrozen(widget)).toBe(true)
		end)

		it("prevents further writes to the instance", function()
			widget:Destroy()
			expect(function()
				widget.IsMounted = true
			end).toThrow()
		end)

		it("makes method calls fail after destruction", function()
			widget:Destroy()

			expect(function()
				widget:Render()
			end).toThrow()
			expect(function()
				widget:MountTo(surfaceGui)
			end).toThrow()
			expect(function()
				widget:Destroy()
			end).toThrow()
		end)

		it("does not affect other widgets", function()
			local other = MovementStateMachineWidget.new(makeStateMachine("Jumping", "Idle"))
			other:MountTo(surfaceGui)
			widget:MountTo(surfaceGui)

			widget:Destroy()

			expect(#surfaceGui:GetChildren()).toBe(1)
			other:Render()
			expect(getCurrentStateText(surfaceGui)).toBe("Jumping")

			other:Destroy()
		end)
	end)

	describe("MovementStateMachineWidget class", function()
		it("exposes the public API", function()
			expect(typeof(MovementStateMachineWidget.new)).toBe("function")
			expect(typeof(MovementStateMachineWidget.MountTo)).toBe("function")
			expect(typeof(MovementStateMachineWidget.Render)).toBe("function")
			expect(typeof(MovementStateMachineWidget.Destroy)).toBe("function")
		end)
	end)
end)