--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ConfirmDialog = require(ReplicatedStorage.ControlCustomization.UIComponents.ConfirmDialog)

local function makeDialog()
	return ConfirmDialog.new({
		Title = "Unsaved changes",
		Message = "Save your layout before leaving?",
		Choices = {
			{ Id = "Save", Text = "Save" },
			{ Id = "Discard", Text = "Discard" },
			{ Id = "Cancel", Text = "Cancel" },
		},
	})
end

describe("ConfirmDialog", function()
	it("shows its title and message", function()
		local dialog = makeDialog():GetGuiObject().Dialog

		expect(dialog.Title.Text).toBe("Unsaved changes")
		expect(dialog.Message.Text).toBe("Save your layout before leaving?")
		expect(dialog.Message.TextWrapped).toBe(true)
	end)

	it("starts hidden, and shows and hides", function()
		local dialog = makeDialog()
		expect(dialog:IsShown()).toBe(false)

		dialog:Show()
		expect(dialog:IsShown()).toBe(true)
		expect(dialog:GetGuiObject().Visible).toBe(true)

		dialog:Hide()
		expect(dialog:IsShown()).toBe(false)
	end)

	it("makes a button per choice, in the order given", function()
		local row = makeDialog():GetGuiObject().Dialog.Buttons

		expect(row.Save.Text).toBe("Save")
		expect(row.Discard.Text).toBe("Discard")
		expect(row.Cancel.Text).toBe("Cancel")
		expect(row.Save.LayoutOrder < row.Discard.LayoutOrder).toBe(true)
		expect(row.Discard.LayoutOrder < row.Cancel.LayoutOrder).toBe(true)
	end)

	it("announces the id of the choice that was pressed", function()
		local dialog = makeDialog()
		local made = {}
		dialog.ChoiceMade:Connect(function(id)
			table.insert(made, id)
		end)

		-- Roblox does not let a script fire a GUI's real input events, so this calls the handler the button is wired to.
		dialog._buttons[2]:_handleActivated()

		expect(made).toEqual({ "Discard" })
	end)

	it("takes every press while up, so nothing behind it can be touched", function()
		expect(makeDialog():GetGuiObject().Active).toBe(true)
	end)
end)
