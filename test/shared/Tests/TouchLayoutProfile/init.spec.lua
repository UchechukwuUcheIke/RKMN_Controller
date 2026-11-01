--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local TouchLayoutProfile = require(ReplicatedStorage.TouchGamepad.TouchLayoutProfile)

local function makeTransform(x)
	return {
		Position = UDim2.fromOffset(x, 0),
		BaseSize = UDim2.fromOffset(80, 80),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}
end

local function makeLayout(x)
	return { Left = makeTransform(x), Jump = makeTransform(x) }
end

describe("TouchLayoutProfile", function()
	it("starts as the live default", function()
		local defaultLayout = makeLayout(10)
		local profile = TouchLayoutProfile.new(defaultLayout)

		expect(profile:GetLayout()).toBe(defaultLayout)
	end)

	it("uses a set layout without changing the default", function()
		local defaultLayout = makeLayout(10)
		local profile = TouchLayoutProfile.new(defaultLayout)

		profile:SetLayout(makeLayout(50))

		expect(profile:GetLayout().Left.Position).toEqual(UDim2.fromOffset(50, 0))
		expect(defaultLayout.Left.Position).toEqual(UDim2.fromOffset(10, 0))
	end)

	it("keeps its own frozen copy of a set layout", function()
		local profile = TouchLayoutProfile.new(makeLayout(10))
		local layout = makeLayout(50)

		profile:SetLayout(layout)
		layout.Left.Position = UDim2.fromOffset(999, 0)

		expect(profile:GetLayout()).never.toBe(layout)
		expect(profile:GetLayout().Left.Position).toEqual(UDim2.fromOffset(50, 0))
		expect(table.isfrozen(profile:GetLayout())).toBe(true)
		expect(table.isfrozen(profile:GetLayout().Left)).toBe(true)
	end)

	it("refuses a layout missing an action", function()
		local profile = TouchLayoutProfile.new(makeLayout(10))

		expect(function()
			profile:SetLayout({ Left = makeTransform(50) })
		end).toThrow()
		expect(profile:GetLayout().Jump.Position).toEqual(UDim2.fromOffset(10, 0))
	end)

	it("fires LayoutChanged when the layout is set", function()
		local profile = TouchLayoutProfile.new(makeLayout(10))
		local fired = 0
		profile.LayoutChanged:Connect(function()
			fired += 1
		end)

		profile:SetLayout(makeLayout(50))

		expect(fired).toBe(1)
	end)

	it("resets to the live default", function()
		local defaultLayout = makeLayout(10)
		local profile = TouchLayoutProfile.new(defaultLayout)
		profile:SetLayout(makeLayout(50))
		local fired = 0
		profile.LayoutChanged:Connect(function()
			fired += 1
		end)

		profile:ResetLayout()

		expect(profile:GetLayout()).toBe(defaultLayout)
		expect(fired).toBe(1)
	end)

	it("does not fire LayoutChanged when resetting an unedited profile", function()
		local profile = TouchLayoutProfile.new(makeLayout(10))
		local fired = 0
		profile.LayoutChanged:Connect(function()
			fired += 1
		end)

		profile:ResetLayout()

		expect(fired).toBe(0)
	end)
end)
