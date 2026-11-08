--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local DPad = require(ReplicatedStorage.TouchGamepad.UserInterface.DPad)

local function makeTransform(scale, transparency)
	return {
		Position = UDim2.fromOffset(100, 200),
		BaseSize = UDim2.fromOffset(190, 80),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Scale = scale,
		Transparency = transparency,
	}
end

describe("DPad", function()
	it("names its arrows after the Left and Right actions", function()
		local dPad = DPad.new()

		expect(dPad:GetLeftButton():GetInstance().Name).toBe("Left")
		expect(dPad:GetRightButton():GetInstance().Name).toBe("Right")
	end)

	it("hands out its frame as the instance a layout places", function()
		local dPad = DPad.new()

		expect(dPad:GetInstance().Name).toBe("DPad")
		expect(dPad:GetLeftButton():GetInstance().Parent).toBe(dPad:GetInstance())
	end)

	it("moves and scales as one unit, with the arrows parented inside it", function()
		local dPad = DPad.new()

		dPad:SetTransform(makeTransform(0.5, 0.5))

		local frame = dPad:GetLeftButton():GetInstance().Parent
		expect(frame).toBe(dPad:GetRightButton():GetInstance().Parent)
		expect(frame.Position).toEqual(UDim2.fromOffset(100, 200))
		expect(frame.Size).toEqual(UDim2.fromOffset(95, 40))
	end)

	it("pins the arrows to opposite edges of the pad", function()
		local dPad = DPad.new()

		dPad:SetTransform(makeTransform(1, 0.5))

		expect(dPad:GetLeftButton():GetInstance().AnchorPoint).toEqual(Vector2.new(0, 0.5))
		expect(dPad:GetRightButton():GetInstance().AnchorPoint).toEqual(Vector2.new(1, 0.5))
	end)

	it("gives both arrows the pad's transparency", function()
		local dPad = DPad.new()

		dPad:SetTransform(makeTransform(1, 0.75))

		expect(dPad:GetLeftButton():GetInstance().BackgroundTransparency).toBe(0.75)
		expect(dPad:GetRightButton():GetInstance().BackgroundTransparency).toBe(0.75)
	end)
end)
