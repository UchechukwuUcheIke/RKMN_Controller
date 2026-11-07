--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local FallbackImage = require(ReplicatedStorage.ControlCustomization.UIComponents.FallbackImage)

-- A script cannot make an image finish loading, so the shown-once-loaded case is not covered here.
describe("FallbackImage", function()
	it("shows the fallback text when no image is given", function()
		local frame = FallbackImage.new({ FallbackText = "W" }):GetGuiObject()

		expect(frame.Fallback.Text).toBe("W")
		expect(frame.Fallback.Visible).toBe(true)
		expect(frame.Image.Visible).toBe(false)
	end)

	it("keeps showing the fallback until the image has loaded", function()
		local frame = FallbackImage.new({ FallbackText = "W", ImageId = "rbxassetid://0" }):GetGuiObject()

		expect(frame.Image.IsLoaded).toBe(false)
		expect(frame.Fallback.Visible).toBe(true)
		expect(frame.Image.Visible).toBe(false)
	end)

	it("changes its fallback text", function()
		local image = FallbackImage.new({ FallbackText = "W" })

		image:SetFallbackText("Space")

		expect(image:GetGuiObject().Fallback.Text).toBe("Space")
	end)

	it("applies its size and layout order", function()
		local frame = FallbackImage.new({ Size = UDim2.fromOffset(30, 30), LayoutOrder = 4 }):GetGuiObject()

		expect(frame.Size).toEqual(UDim2.fromOffset(30, 30))
		expect(frame.LayoutOrder).toBe(4)
	end)
end)
