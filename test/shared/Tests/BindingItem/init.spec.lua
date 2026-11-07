--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local BindingItem = require(ReplicatedStorage.ControlCustomization.UIComponents.BindingItem)

local function deleteButtonIsVisible(item)
	return item:GetGuiObject().Delete.Visible
end

-- Roblox does not let a script fire a GUI's real input events, so these specs call the handlers the events are wired to.
describe("BindingItem", function()
	it("is named after its binding and shows the name", function()
		local item = BindingItem.new({ Binding = Enum.KeyCode.Space, LayoutOrder = 2 })
		local frame = item:GetGuiObject()

		expect(frame.Name).toBe("Space")
		expect(frame.LayoutOrder).toBe(2)
		expect(frame.Content.BindingName.Text).toBe("Space")
	end)

	it("shows the binding's name in the image box while no icon is available", function()
		local item = BindingItem.new({ Binding = Enum.KeyCode.W })
		local imageBox = item:GetGuiObject().Content.FallbackImage

		expect(imageBox.Fallback.Text).toBe("W")
		expect(imageBox.Fallback.Visible).toBe(true)
		expect(imageBox.Image.Visible).toBe(false)
	end)

	it("hides the delete button until the item is hovered", function()
		local item = BindingItem.new({ Binding = Enum.KeyCode.W })
		expect(deleteButtonIsVisible(item)).toBe(false)

		item:_handleItemHoverChanged(true)
		expect(deleteButtonIsVisible(item)).toBe(true)

		item:_handleItemHoverChanged(false)
		expect(deleteButtonIsVisible(item)).toBe(false)
	end)

	it("keeps the delete button while the mouse is over it, even if the item reports leaving", function()
		local item = BindingItem.new({ Binding = Enum.KeyCode.W })
		item:_handleItemHoverChanged(true)
		item:_handleDeleteButtonHoverChanged(true)

		item:_handleItemHoverChanged(false)
		expect(deleteButtonIsVisible(item)).toBe(true)

		item:_handleDeleteButtonHoverChanged(false)
		expect(deleteButtonIsVisible(item)).toBe(false)
	end)

	it("fires DeleteRequested with its binding when the delete button is pressed", function()
		local item = BindingItem.new({ Binding = Enum.KeyCode.W })
		local deleted = {}
		item.DeleteRequested:Connect(function(binding)
			table.insert(deleted, binding)
		end)

		item._deleteButton:_handleActivated()

		expect(deleted).toEqual({ Enum.KeyCode.W })
	end)
end)
