--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local ControlProfile = require(ReplicatedStorage.PlayerInput.ControlProfile)

local function makeProfile()
	local keyboardDefault = {
		Left = { [Enum.KeyCode.A] = true },
		Jump = { [Enum.KeyCode.Space] = true },
		Shoot = { [Enum.KeyCode.C] = true },
	}
	local gamepadDefault = {
		Jump = { [Enum.KeyCode.ButtonA] = true },
	}
	return ControlProfile.new(keyboardDefault, gamepadDefault), keyboardDefault, gamepadDefault
end

describe("ControlProfile", function()
	it("starts as the live defaults", function()
		local profile, keyboardDefault, gamepadDefault = makeProfile()

		expect(profile:GetScheme("keyboard")).toBe(keyboardDefault)
		expect(profile:GetScheme("gamepad")).toBe(gamepadDefault)
	end)

	it("has an empty scheme for touch", function()
		local profile = makeProfile()

		expect(next(profile:GetScheme("touch"))).toBeNil()
	end)

	it("adds a binding without changing the defaults", function()
		local profile, keyboardDefault = makeProfile()

		profile:BindKey("keyboard", "Jump", Enum.KeyCode.J)

		expect(profile:GetScheme("keyboard").Jump[Enum.KeyCode.J]).toBe(true)
		expect(profile:GetScheme("keyboard").Jump[Enum.KeyCode.Space]).toBe(true)
		expect(keyboardDefault.Jump[Enum.KeyCode.J]).toBeNil()
	end)

	it("allows any number of bindings on one action", function()
		local profile = makeProfile()

		profile:BindKey("keyboard", "Jump", Enum.KeyCode.J)
		profile:BindKey("keyboard", "Jump", Enum.KeyCode.K)
		profile:BindKey("keyboard", "Jump", Enum.KeyCode.L)

		local count = 0
		for _ in pairs(profile:GetScheme("keyboard").Jump) do
			count += 1
		end
		expect(count).toBe(4)
	end)

	it("takes a binding from the action that had it", function()
		local profile = makeProfile()

		profile:BindKey("keyboard", "Jump", Enum.KeyCode.C)

		expect(profile:GetScheme("keyboard").Jump[Enum.KeyCode.C]).toBe(true)
		expect(profile:GetScheme("keyboard").Shoot).toBeNil()
	end)

	it("keeps an action's other bindings when one is taken", function()
		local profile = makeProfile()
		profile:BindKey("keyboard", "Shoot", Enum.KeyCode.X)

		profile:BindKey("keyboard", "Jump", Enum.KeyCode.C)

		expect(profile:GetScheme("keyboard").Shoot[Enum.KeyCode.X]).toBe(true)
		expect(profile:GetScheme("keyboard").Shoot[Enum.KeyCode.C]).toBeNil()
	end)

	it("removes a binding and leaves an emptied action unbound", function()
		local profile = makeProfile()

		profile:UnbindKey("keyboard", "Jump", Enum.KeyCode.Space)

		expect(profile:GetScheme("keyboard").Jump).toBeNil()
	end)

	it("keeps each device's edits separate", function()
		local profile = makeProfile()

		profile:BindKey("keyboard", "Jump", Enum.KeyCode.J)

		expect(profile:GetScheme("gamepad").Jump[Enum.KeyCode.J]).toBeNil()
	end)

	it("announces the edited device", function()
		local profile = makeProfile()
		local announced = {}
		profile.SchemeChanged:Connect(function(device)
			table.insert(announced, device)
		end)

		profile:BindKey("gamepad", "Jump", Enum.KeyCode.ButtonY)
		profile:UnbindKey("gamepad", "Jump", Enum.KeyCode.ButtonY)

		expect(announced).toEqual({ "gamepad", "gamepad" })
	end)

	it("ignores edits that change nothing", function()
		local profile, keyboardDefault = makeProfile()
		local announced = 0
		profile.SchemeChanged:Connect(function()
			announced += 1
		end)

		profile:BindKey("keyboard", "Jump", Enum.KeyCode.Space)
		profile:UnbindKey("keyboard", "Jump", Enum.KeyCode.J)

		expect(announced).toBe(0)
		expect(profile:GetScheme("keyboard")).toBe(keyboardDefault)
	end)

	it("returns a device to the live defaults on reset", function()
		local profile, keyboardDefault = makeProfile()
		profile:BindKey("keyboard", "Jump", Enum.KeyCode.J)

		profile:ResetDevice("keyboard")

		expect(profile:GetScheme("keyboard")).toBe(keyboardDefault)
	end)

	it("announces a reset only when there was something to reset", function()
		local profile = makeProfile()
		local announced = 0
		profile.SchemeChanged:Connect(function()
			announced += 1
		end)

		profile:ResetDevice("keyboard")
		profile:BindKey("keyboard", "Jump", Enum.KeyCode.J)
		profile:ResetDevice("keyboard")

		expect(announced).toBe(2)
	end)

	it("errors when asked to edit touch", function()
		local profile = makeProfile()

		expect(function()
			profile:BindKey("touch", "Jump", Enum.KeyCode.J)
		end).toThrow()
	end)
end)
