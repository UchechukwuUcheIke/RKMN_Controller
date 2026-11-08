--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TouchLayoutEditSession = require(ReplicatedStorage.ControlCustomization.TouchLayoutEditSession)
local ButtonTransform = require(ReplicatedStorage.TouchGamepad.ButtonTransform)
local TouchLayout = require(ReplicatedStorage.TouchGamepad.TouchLayout)

local function makeTransform(x)
	return ButtonTransform.new({
		Position = UDim2.fromScale(x, 0.5),
		BaseSize = UDim2.fromOffset(80, 80),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Scale = 1,
		Transparency = 0.5,
	})
end

local function makeLayout()
	return TouchLayout.new({ DPad = makeTransform(0.1), Jump = makeTransform(0.9) })
end

local function makeSession()
	return TouchLayoutEditSession.new(makeLayout())
end

local function positionOf(session, controlID)
	return session:GetLayout():GetTransform(controlID).Position
end

describe("TouchLayoutEditSession", function()
	describe("editing", function()
		it("starts clean, with nothing to undo or redo", function()
			local session = makeSession()

			expect(session:IsDirty()).toBe(false)
			expect(session:CanUndo()).toBe(false)
			expect(session:CanRedo()).toBe(false)
		end)

		it("changes only the edited control and leaves the starting layout alone", function()
			local startingLayout = makeLayout()
			local session = TouchLayoutEditSession.new(startingLayout)

			session:SetPosition("Jump", UDim2.fromScale(0.7, 0.2))

			expect(positionOf(session, "Jump")).toEqual(UDim2.fromScale(0.7, 0.2))
			expect(positionOf(session, "DPad")).toEqual(UDim2.fromScale(0.1, 0.5))
			expect(startingLayout:GetTransform("Jump").Position).toEqual(UDim2.fromScale(0.9, 0.5))
			expect(session:IsDirty()).toBe(true)
		end)

		it("clamps scale and transparency through the rules", function()
			local session = makeSession()

			session:SetScale("Jump", 10)
			session:SetTransparency("Jump", 5)

			expect(session:GetLayout():GetTransform("Jump").Scale).toBe(1.5)
			expect(session:GetLayout():GetTransform("Jump").Transparency).toBe(0.8)
		end)

		it("ignores an edit that changes nothing", function()
			local session = makeSession()
			local fireCount = 0
			session.Changed:Connect(function()
				fireCount += 1
			end)

			session:SetScale("Jump", 1)

			expect(fireCount).toBe(0)
			expect(session:CanUndo()).toBe(false)
		end)

		it("refuses to edit a control the layout does not have", function()
			local session = makeSession()

			expect(function()
				session:SetScale("Fly", 1)
			end).toThrow()
		end)

		it("announces every change", function()
			local session = makeSession()
			local fireCount = 0
			session.Changed:Connect(function()
				fireCount += 1
			end)

			session:SetScale("Jump", 1.2)

			expect(fireCount).toBe(1)
		end)
	end)

	describe("selection", function()
		it("selects a control and clears the selection", function()
			local session = makeSession()

			session:Select("Jump")
			expect(session:GetSelected()).toBe("Jump")

			session:Select(nil)
			expect(session:GetSelected()).toBeNil()
		end)

		it("refuses to select a control the layout does not have", function()
			local session = makeSession()

			expect(function()
				session:Select("Fly")
			end).toThrow()
		end)

		it("does not count selecting as an edit", function()
			local session = makeSession()

			session:Select("Jump")

			expect(session:IsDirty()).toBe(false)
			expect(session:CanUndo()).toBe(false)
		end)
	end)

	describe("undo and redo", function()
		it("undoes and redoes one edit at a time", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)
			session:SetScale("Jump", 1.4)

			session:Undo()
			expect(session:GetLayout():GetTransform("Jump").Scale).toBe(1.2)

			session:Undo()
			expect(session:GetLayout():GetTransform("Jump").Scale).toBe(1)
			expect(session:CanUndo()).toBe(false)

			session:Redo()
			session:Redo()
			expect(session:GetLayout():GetTransform("Jump").Scale).toBe(1.4)
			expect(session:CanRedo()).toBe(false)
		end)

		it("drops the redo steps when a new edit is made", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)
			session:Undo()

			session:SetScale("Jump", 1.4)

			expect(session:CanRedo()).toBe(false)
		end)

		it("does nothing when there is nothing to undo or redo", function()
			local session = makeSession()

			session:Undo()
			session:Redo()

			expect(session:IsDirty()).toBe(false)
		end)

		it("is clean again once undone back to the starting layout", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)

			session:Undo()

			expect(session:IsDirty()).toBe(false)
		end)

		it("announces undo and redo", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)
			local fireCount = 0
			session.Changed:Connect(function()
				fireCount += 1
			end)

			session:Undo()
			session:Redo()

			expect(fireCount).toBe(2)
		end)
	end)

	describe("gestures", function()
		it("makes everything in one gesture a single undo step", function()
			local session = makeSession()

			session:BeginGesture()
			session:SetPosition("Jump", UDim2.fromScale(0.8, 0.5))
			session:SetPosition("Jump", UDim2.fromScale(0.7, 0.5))
			session:SetPosition("Jump", UDim2.fromScale(0.6, 0.5))
			session:EndGesture()

			expect(positionOf(session, "Jump")).toEqual(UDim2.fromScale(0.6, 0.5))

			session:Undo()
			expect(positionOf(session, "Jump")).toEqual(UDim2.fromScale(0.9, 0.5))
			expect(session:CanUndo()).toBe(false)
		end)

		it("shows the draft changing while the gesture is still open", function()
			local session = makeSession()

			session:BeginGesture()
			session:SetPosition("Jump", UDim2.fromScale(0.8, 0.5))

			expect(positionOf(session, "Jump")).toEqual(UDim2.fromScale(0.8, 0.5))
			expect(session:IsDirty()).toBe(true)
		end)

		it("records no step for a gesture that changed nothing", function()
			local session = makeSession()

			session:BeginGesture()
			session:SetScale("Jump", 1.2)
			session:SetScale("Jump", 1)
			session:EndGesture()

			expect(session:CanUndo()).toBe(false)
		end)

		it("holds off undo and redo until the gesture ends", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)

			session:BeginGesture()

			expect(session:CanUndo()).toBe(false)
			session:EndGesture()
			expect(session:CanUndo()).toBe(true)
		end)

		it("refuses to begin a second gesture while one is open", function()
			local session = makeSession()
			session:BeginGesture()

			expect(function()
				session:BeginGesture()
			end).toThrow()
		end)

		it("treats ending a gesture that never began as nothing", function()
			local session = makeSession()

			session:EndGesture()

			expect(session:CanUndo()).toBe(false)
		end)
	end)

	describe("saving and discarding", function()
		it("becomes clean once marked saved, and keeps its history", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)

			session:MarkSaved()

			expect(session:IsDirty()).toBe(false)
			expect(session:CanUndo()).toBe(true)
		end)

		it("is dirty again when undone past the saved layout", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)
			session:MarkSaved()

			session:Undo()

			expect(session:IsDirty()).toBe(true)
		end)

		it("discards edits back to the last saved layout in one undoable step", function()
			local session = makeSession()
			session:SetScale("Jump", 1.2)
			session:MarkSaved()
			session:SetScale("Jump", 1.4)
			session:SetPosition("DPad", UDim2.fromScale(0.3, 0.5))

			session:DiscardChanges()

			expect(session:GetLayout():GetTransform("Jump").Scale).toBe(1.2)
			expect(positionOf(session, "DPad")).toEqual(UDim2.fromScale(0.1, 0.5))
			expect(session:IsDirty()).toBe(false)

			session:Undo()
			expect(session:GetLayout():GetTransform("Jump").Scale).toBe(1.4)
			expect(positionOf(session, "DPad")).toEqual(UDim2.fromScale(0.3, 0.5))
		end)

		it("does nothing when discarding with no unsaved edits", function()
			local session = makeSession()

			session:DiscardChanges()

			expect(session:CanUndo()).toBe(false)
		end)
	end)
end)
