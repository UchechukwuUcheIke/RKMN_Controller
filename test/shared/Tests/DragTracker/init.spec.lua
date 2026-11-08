--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DragTracker = require(ReplicatedStorage.ControlCustomization.UIComponents.DragTracker)

local function makeInput(inputType, x, y)
	return { UserInputType = inputType, Position = Vector3.new(x or 0, y or 0, 0) }
end

local function record(tracker)
	local events = {}
	tracker.Began:Connect(function(position)
		table.insert(events, { "began", position })
	end)
	tracker.Moved:Connect(function(position)
		table.insert(events, { "moved", position })
	end)
	tracker.Ended:Connect(function()
		table.insert(events, { "ended" })
	end)
	return events
end

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the events are wired to.
describe("DragTracker", function()
	it("reports where a click began, then where the mouse moves, then the end", function()
		local tracker = DragTracker.new(Instance.new("Frame"))
		local events = record(tracker)

		tracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton1, 10, 20))
		tracker:_handleInputChanged(makeInput(Enum.UserInputType.MouseMovement, 30, 40))
		tracker:_handleInputEnded(makeInput(Enum.UserInputType.MouseButton1))

		expect(events).toEqual({
			{ "began", Vector2.new(10, 20) },
			{ "moved", Vector2.new(30, 40) },
			{ "ended" },
		})
		expect(tracker:IsDragging()).toBe(false)
	end)

	it("ignores presses that are not a click or a touch", function()
		local tracker = DragTracker.new(Instance.new("Frame"))

		tracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton2))

		expect(tracker:IsDragging()).toBe(false)
	end)

	it("ignores mouse movement when no drag is in progress", function()
		local tracker = DragTracker.new(Instance.new("Frame"))
		local events = record(tracker)

		tracker:_handleInputChanged(makeInput(Enum.UserInputType.MouseMovement, 5, 5))

		expect(#events).toBe(0)
	end)

	it("follows only the touch that started the drag", function()
		local tracker = DragTracker.new(Instance.new("Frame"))
		local events = record(tracker)
		local firstFinger = makeInput(Enum.UserInputType.Touch, 1, 1)
		local secondFinger = makeInput(Enum.UserInputType.Touch, 9, 9)
		tracker:_handleInputBegan(firstFinger)

		tracker:_handleInputChanged(secondFinger)
		tracker:_handleInputEnded(secondFinger)
		expect(tracker:IsDragging()).toBe(true)
		expect(#events).toBe(1)

		tracker:_handleInputEnded(firstFinger)
		expect(tracker:IsDragging()).toBe(false)
	end)

	it("does not start a second drag while one is in progress", function()
		local tracker = DragTracker.new(Instance.new("Frame"))
		local events = record(tracker)

		tracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton1))
		tracker:_handleInputBegan(makeInput(Enum.UserInputType.Touch))

		expect(#events).toBe(1)
	end)

	it("cannot start a drag while disabled, and disabling ends one in progress", function()
		local tracker = DragTracker.new(Instance.new("Frame"))
		local events = record(tracker)
		tracker:Disable()

		tracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton1))
		expect(tracker:IsDragging()).toBe(false)

		tracker:Enable()
		tracker:_handleInputBegan(makeInput(Enum.UserInputType.MouseButton1))
		tracker:Disable()

		expect(tracker:IsDragging()).toBe(false)
		expect(events[#events]).toEqual({ "ended" })
	end)
end)
