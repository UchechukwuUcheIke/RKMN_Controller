--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local InputMapper = require(ReplicatedStorage.PlayerInput.InputMapper)
local KeyboardSchemes = require(ReplicatedStorage.PlayerInput.KeyboardSchemes)
local GamepadSchemes = require(ReplicatedStorage.PlayerInput.GamepadSchemes)

local function makeMapper()
	local mapper = InputMapper.new()
	mapper:LoadControlScheme({
		Jump = { [Enum.KeyCode.Space] = true },
		Dash = { [Enum.KeyCode.LeftShift] = true },
	})
	return mapper
end

local function countChanges(mapper)
	local changes = { count = 0 }
	mapper.InputSchemeChanged:Connect(function()
		changes.count += 1
	end)
	return changes
end

describe("InputMapper", function()
	it("maps keys to actions and actions to keys after loading a scheme", function()
		local mapper = makeMapper()

		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBe("Jump")
		expect(mapper:GetKeysForAction("Dash")[Enum.KeyCode.LeftShift]).toBe(true)
		expect(mapper:GetActionForKey(Enum.KeyCode.Q)).toBeNil()
	end)

	it("loads every registered scheme", function()
		for deviceName, schemes in pairs({ Keyboard = KeyboardSchemes, Gamepad = GamepadSchemes }) do
			for name, scheme in pairs(schemes) do
				local ok, message = pcall(function()
					InputMapper.new():LoadControlScheme(scheme)
				end)
				if not ok then
					error(`{deviceName}.{name}: {message}`)
				end
				expect(ok).toBe(true)
			end
		end
	end)

	it("rejects a scheme that binds one key to two actions and keeps the old scheme", function()
		local mapper = makeMapper()

		expect(function()
			mapper:LoadControlScheme({
				Jump = { [Enum.KeyCode.Space] = true },
				Dash = { [Enum.KeyCode.Space] = true },
			})
		end).toThrow()

		expect(mapper:GetActionForKey(Enum.KeyCode.LeftShift)).toBe("Dash")
	end)

	it("moves a key from the action that had it", function()
		local mapper = makeMapper()

		mapper:BindKeyToAction("Dash", Enum.KeyCode.Space)

		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBe("Dash")
		expect(mapper:GetKeysForAction("Jump")).toBeNil()
	end)

	it("unbinds only a key that belongs to the action", function()
		local mapper = makeMapper()

		mapper:UnbindKeyFromAction("Dash", Enum.KeyCode.Space)
		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBe("Jump")

		mapper:UnbindKeyFromAction("Jump", Enum.KeyCode.Space)
		expect(mapper:GetActionForKey(Enum.KeyCode.Space)).toBeNil()
	end)

	it("fires InputSchemeChanged once per real change", function()
		local mapper = makeMapper()
		local changes = countChanges(mapper)

		mapper:BindKeyToAction("Dash", Enum.KeyCode.Space)
		expect(changes.count).toBe(1)

		mapper:BindKeyToAction("Dash", Enum.KeyCode.Space)
		mapper:UnbindKeyFromAction("Jump", Enum.KeyCode.Space)
		expect(changes.count).toBe(1)
	end)
end)
