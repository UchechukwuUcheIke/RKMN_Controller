--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TouchLayout = require(ReplicatedStorage.TouchGamepad.TouchLayout)
local ButtonTransform = require(ReplicatedStorage.TouchGamepad.ButtonTransform)

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

describe("TouchLayout", function()
	it("looks up a control's transform and reports which controls it has", function()
		local layout = makeLayout()

		expect(layout:HasControl("Jump")).toBe(true)
		expect(layout:HasControl("Dash")).toBe(false)
		expect(layout:GetTransform("Jump").Position).toEqual(UDim2.fromScale(0.9, 0.5))
		expect(layout:GetTransform("Dash")).toBeNil()

		local controlIDs = layout:GetControlIDs()
		table.sort(controlIDs)
		expect(controlIDs).toEqual({ "DPad", "Jump" })
	end)

	it("is not changed by later edits to the table it was made from", function()
		local transforms = { Jump = makeTransform(0.9) }
		local layout = TouchLayout.new(transforms)

		transforms.Jump = makeTransform(0.1)
		transforms.Dash = makeTransform(0.5)

		expect(layout:GetTransform("Jump").Position).toEqual(UDim2.fromScale(0.9, 0.5))
		expect(layout:HasControl("Dash")).toBe(false)
		expect(table.isfrozen(layout)).toBe(true)
	end)

	describe("CopyWithTransform", function()
		it("returns a new layout with one control's transform replaced", function()
			local original = makeLayout()

			local edited = original:CopyWithTransform("Jump", makeTransform(0.7))

			expect(edited:GetTransform("Jump").Position).toEqual(UDim2.fromScale(0.7, 0.5))
			expect(edited:GetTransform("DPad")).toBe(original:GetTransform("DPad"))
			expect(original:GetTransform("Jump").Position).toEqual(UDim2.fromScale(0.9, 0.5))
		end)

		it("refuses a control the layout does not have", function()
			expect(function()
				makeLayout():CopyWithTransform("Dash", makeTransform(0.5))
			end).toThrow()
		end)
	end)

	describe("Equals", function()
		it("is true for layouts with equal transforms, even when they are separate objects", function()
			expect(makeLayout():Equals(makeLayout())).toBe(true)
		end)

		it("is false when one control's transform differs", function()
			local original = makeLayout()

			expect(original:Equals(original:CopyWithTransform("Jump", makeTransform(0.7)))).toBe(false)
		end)

		it("is false when the layouts place different controls, whichever side has the extra", function()
			local small = TouchLayout.new({ Jump = makeTransform(0.9) })
			local large = TouchLayout.new({ Jump = makeTransform(0.9), Dash = makeTransform(0.5) })

			expect(small:Equals(large)).toBe(false)
			expect(large:Equals(small)).toBe(false)
		end)
	end)

	describe("HasAllControlsOf", function()
		it("is true when the other layout's controls are all present, even with extras", function()
			local small = TouchLayout.new({ Jump = makeTransform(0.9) })
			local large = TouchLayout.new({ Jump = makeTransform(0.9), Dash = makeTransform(0.5) })

			expect(large:HasAllControlsOf(small)).toBe(true)
			expect(small:HasAllControlsOf(large)).toBe(false)
		end)
	end)
end)
