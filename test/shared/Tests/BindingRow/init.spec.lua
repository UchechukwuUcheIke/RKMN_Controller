--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local BindingRow = require(ReplicatedStorage.ControlCustomization.BindingRow)
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local UITheme = require(ReplicatedStorage.ControlCustomization.UIComponents.UITheme)

local function bindingsText(row)
	return row:GetGuiObject().Bindings.Text
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

		expect(bindingsText(row)).toBe("Unbound")
	end)

	it("lists bound names alphabetically and skips unbound entries", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })

		row:SetBindings({
			[Enum.KeyCode.Space] = true,
			[Enum.KeyCode.W] = true,
			[Enum.KeyCode.Up] = false,
		})

		expect(bindingsText(row)).toBe("Space, W")
	end)

	it("shows Unbound for a missing or empty binding set", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })
		row:SetBindings({ [Enum.KeyCode.Space] = true })

		row:SetBindings({})
		expect(bindingsText(row)).toBe("Unbound")

		row:SetBindings({ [Enum.KeyCode.Space] = true })
		row:SetBindings(nil)
		expect(bindingsText(row)).toBe("Unbound")
	end)

	it("highlights and shows ... while capturing, then restores", function()
		local row = BindingRow.new({ ActionName = InputAction.Jump })
		local frame = row:GetGuiObject()

		row:SetCapturing(true)
		expect(frame.Rebind.Text).toBe("...")
		expect(frame.BackgroundColor3).toEqual(UITheme.Colors.RowHighlighted)

		row:SetCapturing(false)
		expect(frame.Rebind.Text).toBe("Rebind")
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
end)
