--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local BindingRow = require(ReplicatedStorage.ControlCustomization.UIComponents.BindingRow)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local UITheme = require(ReplicatedStorage.ControlCustomization.UIComponents.UITheme)

local function itemNames(row)
	local names = {}
	for _, child in ipairs(row:GetGuiObject().Bindings:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(names, child.Name)
		end
	end
	table.sort(names)
	return names
end

local function itemFor(row, bindingName)
	return row:GetGuiObject().Bindings[bindingName]
end

describe("BindingRow", function()
	it("is named after its action and ordered by the given layout order", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump, LayoutOrder = 3 })
		local frame = row:GetGuiObject()

		expect(frame.Name).toBe(InputAction.Jump)
		expect(frame.LayoutOrder).toBe(3)
		expect(frame.ActionName.Text).toBe(InputAction.Jump)
	end)

	it("starts out showing Unbound", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })

		expect(row:GetGuiObject().Bindings.Unbound.Text).toBe("Unbound")
	end)

	it("makes one item per bound binding and skips unbound entries", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })

		row:SetBindings({
			[Enum.KeyCode.Space] = true,
			[Enum.KeyCode.W] = true,
			[Enum.KeyCode.Up] = false,
		})

		expect(itemNames(row)).toEqual({ "Space", "W" })
		expect(row:GetGuiObject().Bindings:FindFirstChild("Unbound")).toBeNil()
	end)

	it("orders items by name", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })

		row:SetBindings({ [Enum.KeyCode.W] = true, [Enum.KeyCode.Space] = true })

		expect(itemFor(row, "Space").LayoutOrder < itemFor(row, "W").LayoutOrder).toBe(true)
	end)

	it("replaces its items when the bindings change", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })
		row:SetBindings({ [Enum.KeyCode.Space] = true })

		row:SetBindings({ [Enum.KeyCode.W] = true })

		expect(itemNames(row)).toEqual({ "W" })
	end)

	it("shows Unbound again for a missing or empty binding set", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })
		row:SetBindings({ [Enum.KeyCode.Space] = true })

		row:SetBindings({})
		expect(itemNames(row)).toEqual({})
		expect(row:GetGuiObject().Bindings.Unbound.Text).toBe("Unbound")

		row:SetBindings({ [Enum.KeyCode.Space] = true })
		row:SetBindings(nil)
		expect(row:GetGuiObject().Bindings.Unbound.Text).toBe("Unbound")
	end)

	it("scrolls its items sideways so any number of bindings fit", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })
		local container = row:GetGuiObject().Bindings

		expect(container:IsA("ScrollingFrame")).toBe(true)
		expect(container.ScrollingDirection).toBe(Enum.ScrollingDirection.X)
		expect(container.AutomaticCanvasSize).toBe(Enum.AutomaticSize.X)
	end)

	it("highlights and shows ... while capturing, then restores", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })
		local frame = row:GetGuiObject()

		row:SetCapturing(true)
		expect(frame.Rebind.Text).toBe("...")
		expect(frame.BackgroundColor3).toEqual(UITheme.Colors.RowHighlighted)

		row:SetCapturing(false)
		expect(frame.Rebind.Text).toBe("Add Binding")
		expect(frame.BackgroundColor3).toEqual(UITheme.Colors.Row)
	end)

	it("fires RebindRequested with its action when Rebind is pressed", function()
		local row = BindingRow.new({ ActionName = InputAction.Dash })
		local requested = {}
		row.RebindRequested:Connect(function(actionName)
			table.insert(requested, actionName)
		end)

		-- Roblox does not let a script fire a GUI's real input events, so this calls the handler the button is wired to.
		row._rebindButton:_handleActivated()

		expect(requested).toEqual({ InputAction.Dash })
	end)

	it("fires BindingDeleteRequested with its action and the deleted binding", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })
		row:SetBindings({ [Enum.KeyCode.Space] = true, [Enum.KeyCode.W] = true })
		local requested = {}
		row.BindingDeleteRequested:Connect(function(actionName, binding)
			table.insert(requested, { actionName, binding })
		end)

		row._items[1]._deleteButton:_handleActivated()

		expect(requested).toEqual({ { InputAction.Jump, Enum.KeyCode.Space } })
	end)
end)
