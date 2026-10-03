--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local MockWorldFolder = ReplicatedStorage.MockWorld
local MockWorld = require(MockWorldFolder.MockWorld)
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DebugModuleFolder = RKMNControllerFolder.DebugModule
local WidgetsFolder = DebugModuleFolder.Widgets
local DataRow = require(WidgetsFolder.DataRow)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

type DataRow = DataRow.DataRow

local ROW_PREFIX = "DataRow_"

local function findCanvas(gui: SurfaceGui, labelText: string): Frame?
	return gui:FindFirstChild(ROW_PREFIX .. labelText) :: Frame?
end

describe("DataRow", function()
	local mockWorld
	local part: Part
	local surfaceGui: SurfaceGui
	local row

	beforeEach(function()
		mockWorld = MockWorld.new()
		part = mockWorld:SpawnPart()

		surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Parent = part

		row = DataRow.new("Health", "100")
	end)

	afterEach(function()
		-- Destroy() strips the metatable, so guard against destroying a row twice
		if row and getmetatable(row) ~= nil then
			row:Destroy()
		end
		row = nil
		mockWorld:Destroy()
		mockWorld = nil
	end)

	describe("MockWorld setup", function()
		it("parents the SurfaceGui to the spawned part", function()
			expect(surfaceGui.Parent).toBe(part)
		end)

		it("starts with an empty SurfaceGui", function()
			expect(#surfaceGui:GetChildren()).toBe(0)
		end)
	end)

	describe("new", function()
		it("returns a table", function()
			expect(typeof(row)).toBe("table")
		end)

		it("uses DataRow as its metatable", function()
			expect(getmetatable(row)).toBe(DataRow)
		end)

		it("stores the label text as the key text", function()
			expect(row:GetKeyText()).toBe("Health")
		end)

		it("stores the initial value as the value text", function()
			expect(row:GetValueText()).toBe("100")
		end)

		it("does not parent anything to the SurfaceGui on creation", function()
			expect(#surfaceGui:GetChildren()).toBe(0)
		end)

		it("creates independent instances", function()
			local other = DataRow.new("Mana", "50")

			expect(other:GetKeyText()).toBe("Mana")
			expect(other:GetValueText()).toBe("50")
			expect(row:GetKeyText()).toBe("Health")
			expect(row:GetValueText()).toBe("100")

			other:Destroy()
		end)

		it("accepts empty strings", function()
			local empty = DataRow.new("", "")

			expect(empty:GetKeyText()).toBe("")
			expect(empty:GetValueText()).toBe("")

			empty:Destroy()
		end)
	end)

	describe("GetKeyText", function()
		it("returns the label text passed to new", function()
			expect(row:GetKeyText()).toBe("Health")
		end)

		it("returns a string", function()
			expect(typeof(row:GetKeyText())).toBe("string")
		end)

		it("is not changed by UpdateValue", function()
			row:UpdateValue("75")
			expect(row:GetKeyText()).toBe("Health")
		end)
	end)

	describe("GetValueText", function()
		it("returns the initial value passed to new", function()
			expect(row:GetValueText()).toBe("100")
		end)

		it("returns a string", function()
			expect(typeof(row:GetValueText())).toBe("string")
		end)

		it("reflects the latest UpdateValue call", function()
			row:UpdateValue("42")
			expect(row:GetValueText()).toBe("42")
		end)
	end)

	describe("UI structure", function()
		local canvas: Frame
		local keyLabel: TextLabel
		local valueLabel: TextLabel

		beforeEach(function()
			row:MountTo(surfaceGui)
			canvas = findCanvas(surfaceGui, "Health")
			keyLabel = canvas:FindFirstChild("KeyLabel")
			valueLabel = canvas:FindFirstChild("ValueLabel")
		end)

		it("creates a Frame canvas named after the label", function()
			expect(canvas).toBeDefined()
			expect(canvas:IsA("Frame")).toBe(true)
			expect(canvas.Name).toBe("DataRow_Health")
		end)

		it("makes the canvas background transparent", function()
			expect(canvas.BackgroundTransparency).toBe(1)
		end)

		it("creates exactly two children on the canvas", function()
			expect(#canvas:GetChildren()).toBe(2)
		end)

		it("names the canvas after each row's label", function()
			local other = DataRow.new("Mana", "50")
			other:MountTo(surfaceGui)

			expect(findCanvas(surfaceGui, "Mana")).toBeDefined()
			expect(findCanvas(surfaceGui, "Mana")).never.toBe(canvas)

			other:Destroy()
		end)

		describe("key label", function()
			it("is a TextLabel parented to the canvas", function()
				expect(keyLabel).toBeDefined()
				expect(keyLabel:IsA("TextLabel")).toBe(true)
				expect(keyLabel.Parent).toBe(canvas)
			end)

			it("displays the label text", function()
				expect(keyLabel.Text).toBe("Health")
				expect(keyLabel.Text).toBe(row:GetKeyText())
			end)

			it("has a transparent background", function()
				expect(keyLabel.BackgroundTransparency).toBe(1)
			end)

			it("uses RobotoMono at size 14", function()
				expect(keyLabel.Font).toBe(Enum.Font.RobotoMono)
				expect(keyLabel.TextSize).toBe(14)
			end)

			it("is left-aligned", function()
				expect(keyLabel.TextXAlignment).toBe(Enum.TextXAlignment.Left)
			end)
		end)

		describe("value label", function()
			it("is a TextLabel parented to the canvas", function()
				expect(valueLabel).toBeDefined()
				expect(valueLabel:IsA("TextLabel")).toBe(true)
				expect(valueLabel.Parent).toBe(canvas)
			end)

			it("displays the initial value", function()
				expect(valueLabel.Text).toBe("100")
				expect(valueLabel.Text).toBe(row:GetValueText())
			end)

			it("has a transparent background", function()
				expect(valueLabel.BackgroundTransparency).toBe(1)
			end)

			it("uses RobotoMono at size 14", function()
				expect(valueLabel.Font).toBe(Enum.Font.RobotoMono)
				expect(valueLabel.TextSize).toBe(14)
			end)

			it("is right-aligned", function()
				expect(valueLabel.TextXAlignment).toBe(Enum.TextXAlignment.Right)
			end)

			it("has white text", function()
				expect(valueLabel.TextColor3).toEqual(Color3.new(1, 1, 1))
			end)
		end)
	end)

	describe("MountTo", function()
		it("parents the row's canvas to the SurfaceGui", function()
			row:MountTo(surfaceGui)

			local canvas = findCanvas(surfaceGui, "Health")
			expect(canvas).toBeDefined()
			expect(canvas.Parent).toBe(surfaceGui)
		end)

		it("makes the labels descendants of the SurfaceGui", function()
			row:MountTo(surfaceGui)

			local canvas = findCanvas(surfaceGui, "Health")
			expect(canvas:FindFirstChild("KeyLabel"):IsDescendantOf(surfaceGui)).toBe(true)
			expect(canvas:FindFirstChild("ValueLabel"):IsDescendantOf(surfaceGui)).toBe(true)
		end)

		it("makes the row a descendant of the spawned part", function()
			row:MountTo(surfaceGui)
			expect(findCanvas(surfaceGui, "Health"):IsDescendantOf(part)).toBe(true)
		end)

		it("can move the row to a different parent", function()
			local otherGui = Instance.new("SurfaceGui")
			otherGui.Parent = part

			row:MountTo(surfaceGui)
			row:MountTo(otherGui)

			expect(findCanvas(surfaceGui, "Health")).toBeNil()
			expect(findCanvas(otherGui, "Health")).toBeDefined()

			otherGui:Destroy()
		end)

		it("supports multiple rows under one SurfaceGui", function()
			local second = DataRow.new("Mana", "50")
			row:MountTo(surfaceGui)
			second:MountTo(surfaceGui)

			expect(#surfaceGui:GetChildren()).toBe(2)
			expect(findCanvas(surfaceGui, "Health")).toBeDefined()
			expect(findCanvas(surfaceGui, "Mana")).toBeDefined()

			second:Destroy()
		end)

		it("can be mounted to a non-GUI parent", function()
			local folder = Instance.new("Folder")
			row:MountTo(folder)

			expect(folder:FindFirstChild("DataRow_Health")).toBeDefined()
			folder:Destroy()
		end)
	end)

	describe("Dismount", function()
		it("removes the row's canvas from the SurfaceGui", function()
			row:MountTo(surfaceGui)
			row:Dismount()

			expect(findCanvas(surfaceGui, "Health")).toBeNil()
			expect(#surfaceGui:GetChildren()).toBe(0)
		end)

		it("only removes the dismounted row", function()
			local second = DataRow.new("Mana", "50")
			row:MountTo(surfaceGui)
			second:MountTo(surfaceGui)

			row:Dismount()

			expect(findCanvas(surfaceGui, "Health")).toBeNil()
			expect(findCanvas(surfaceGui, "Mana")).toBeDefined()

			second:Destroy()
		end)

		it("keeps the row's text intact", function()
			row:MountTo(surfaceGui)
			row:Dismount()

			expect(row:GetKeyText()).toBe("Health")
			expect(row:GetValueText()).toBe("100")
		end)

		it("keeps the value updates made while dismounted", function()
			row:MountTo(surfaceGui)
			row:Dismount()
			row:UpdateValue("55")

			expect(row:GetValueText()).toBe("55")
		end)

		it("does nothing when the row was never mounted", function()
			expect(function()
				row:Dismount()
			end).never.toThrow()
			expect(#surfaceGui:GetChildren()).toBe(0)
		end)

		it("can be mounted again after dismounting", function()
			row:MountTo(surfaceGui)
			row:Dismount()
			row:MountTo(surfaceGui)

			expect(findCanvas(surfaceGui, "Health")).toBeDefined()
			expect(#surfaceGui:GetChildren()).toBe(1)
		end)

		it("shows the latest value after remounting", function()
			row:MountTo(surfaceGui)
			row:Dismount()
			row:UpdateValue("7")
			row:MountTo(surfaceGui)

			local valueLabel = findCanvas(surfaceGui, "Health"):FindFirstChild("ValueLabel")
			expect(valueLabel.Text).toBe("7")
		end)
	end)

	describe("UpdateValue", function()
		it("changes the value text", function()
			row:UpdateValue("75")
			expect(row:GetValueText()).toBe("75")
		end)

		it("does not change the key text", function()
			row:UpdateValue("75")
			expect(row:GetKeyText()).toBe("Health")
		end)

		it("keeps the same text when given the current value", function()
			row:UpdateValue("100")
			expect(row:GetValueText()).toBe("100")
		end)

		it("handles successive updates", function()
			row:UpdateValue("1")
			row:UpdateValue("2")
			row:UpdateValue("3")
			expect(row:GetValueText()).toBe("3")
		end)

		it("can return to a previous value", function()
			row:UpdateValue("5")
			row:UpdateValue("100")
			expect(row:GetValueText()).toBe("100")
		end)

		it("accepts an empty string", function()
			row:UpdateValue("")
			expect(row:GetValueText()).toBe("")
		end)

		it("accepts long strings", function()
			local long = string.rep("x", 500)
			row:UpdateValue(long)
			expect(row:GetValueText()).toBe(long)
		end)

		it("updates the on-screen label while mounted", function()
			row:MountTo(surfaceGui)
			row:UpdateValue("42")

			local valueLabel = findCanvas(surfaceGui, "Health"):FindFirstChild("ValueLabel")
			expect(valueLabel.Text).toBe("42")
		end)

		it("only updates its own row", function()
			local second = DataRow.new("Mana", "50")
			row:UpdateValue("1")

			expect(row:GetValueText()).toBe("1")
			expect(second:GetValueText()).toBe("50")

			second:Destroy()
		end)
	end)

	describe("Destroy", function()
		it("destroys the canvas", function()
			row:MountTo(surfaceGui)
			local canvas = findCanvas(surfaceGui, "Health")

			local destroyed = false
			canvas.Destroying:Once(function()
				destroyed = true
			end)

			row:Destroy()

			expect(destroyed).toBe(true)
			expect(canvas.Parent).toBeNil()
		end)

		it("removes the row from the SurfaceGui", function()
			row:MountTo(surfaceGui)
			row:Destroy()

			expect(findCanvas(surfaceGui, "Health")).toBeNil()
			expect(#surfaceGui:GetChildren()).toBe(0)
		end)

		it("destroys the child labels along with the canvas", function()
			row:MountTo(surfaceGui)
			local canvas = findCanvas(surfaceGui, "Health")
			local keyLabel = canvas:FindFirstChild("KeyLabel")
			local valueLabel = canvas:FindFirstChild("ValueLabel")

			row:Destroy()

			expect(keyLabel.Parent).toBeNil()
			expect(valueLabel.Parent).toBeNil()
		end)

		it("does not throw when the row was never mounted", function()
			expect(function()
				row:Destroy()
			end).never.toThrow()
		end)

		it("removes the metatable", function()
			row:Destroy()
			expect(getmetatable(row)).toBeNil()
		end)

		it("freezes the instance table", function()
			row:Destroy()
			expect(table.isfrozen(row)).toBe(true)
		end)

		it("prevents further writes to the instance", function()
			row:Destroy()
			expect(function()
				row._canvas = nil
			end).toThrow()
		end)

		it("makes method calls fail after destruction", function()
			row:Destroy()

			expect(function()
				row:UpdateValue("x")
			end).toThrow()
			expect(function()
				row:GetValueText()
			end).toThrow()
			expect(function()
				row:GetKeyText()
			end).toThrow()
			expect(function()
				row:MountTo(surfaceGui)
			end).toThrow()
		end)

		it("does not affect other rows", function()
			local other = DataRow.new("Mana", "50")
			other:MountTo(surfaceGui)
			row:MountTo(surfaceGui)

			row:Destroy()

			expect(#surfaceGui:GetChildren()).toBe(1)
			expect(findCanvas(surfaceGui, "Mana")).toBeDefined()
			expect(other:GetValueText()).toBe("50")

			other:Destroy()
		end)
	end)

	describe("DataRow class", function()
		it("is frozen", function()
			expect(table.isfrozen(DataRow)).toBe(true)
		end)

		it("exposes the public API", function()
			expect(typeof(DataRow.new)).toBe("function")
			expect(typeof(DataRow.MountTo)).toBe("function")
			expect(typeof(DataRow.Dismount)).toBe("function")
			expect(typeof(DataRow.UpdateValue)).toBe("function")
			expect(typeof(DataRow.GetValueText)).toBe("function")
			expect(typeof(DataRow.GetKeyText)).toBe("function")
			expect(typeof(DataRow.Destroy)).toBe("function")
		end)
	end)
end)