--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNController = ReplicatedStorage:WaitForChild("RKMNController")
local FSMContext = require(RKMNController:WaitForChild("FSMContext"))

return function()
	
	type FSMContextDependencies = FSMContext.FSMContextDependencies

	local function createDependencies(overrides: { [string]: any }?): FSMContextDependencies
		local defaults = {
			InputController = { stub = "InputController" },
			CollisionQuery = { stub = "CollisionQuery" },
			PhysicsResolver = { stub = "PhysicsResolver" },
			TimerUtility = { stub = "TimerUtility" },
		}

		if overrides then
			for key, value in overrides do
				defaults[key] = value
			end
		end

		return (defaults :: any) :: FSMContextDependencies
	end

	describe("FSMContext.new", function()
		it("should store the InputController dependency", function()
			local deps = createDependencies()
			local context = FSMContext.new(deps)

			expect(context.InputController).to.equal(deps.InputController)
		end)

		it("should store the CollisionQuery dependency", function()
			local deps = createDependencies()
			local context = FSMContext.new(deps)

			expect(context.CollisionQuery).to.equal(deps.CollisionQuery)
		end)

		it("should store the PhysicsResolver dependency", function()
			local deps = createDependencies()
			local context = FSMContext.new(deps)

			expect(context.PhysicsResolver).to.equal(deps.PhysicsResolver)
		end)

		it("should store the TimerUtility dependency when provided", function()
			local deps = createDependencies()
			local context = FSMContext.new(deps)

			expect(context.TimerUtility).to.equal(deps.TimerUtility)
		end)

		it("should leave TimerUtility nil when not provided, since it's optional", function()
			local deps = createDependencies({ TimerUtility = nil })
			local context = FSMContext.new(deps)

			expect(context.TimerUtility).to.equal(nil)
		end)
	end)

	describe("flag management", function()
		local context

		beforeEach(function()
			context = FSMContext.new(createDependencies())
		end)

		it("HasFlag should return false for a flag that was never set", function()
			expect(context:HasFlag("Jumping")).to.equal(false)
		end)

		it("SetFlag should make HasFlag return true for that key", function()
			context:SetFlag("Jumping")
			expect(context:HasFlag("Jumping")).to.equal(true)
		end)

		it("SetFlag should not affect other flags", function()
			context:SetFlag("Jumping")
			expect(context:HasFlag("Crouching")).to.equal(false)
		end)

		it("ClearFlag should turn a set flag back off", function()
			context:SetFlag("Jumping")
			context:ClearFlag("Jumping")

			expect(context:HasFlag("Jumping")).to.equal(false)
		end)

		it("ClearAllFlags should clear every previously set flag", function()
			context:SetFlag("Jumping")
			context:SetFlag("Crouching")
			context:SetFlag("Sprinting")

			context:ClearAllFlags()

			expect(context:HasFlag("Jumping")).to.equal(false)
			expect(context:HasFlag("Crouching")).to.equal(false)
			expect(context:HasFlag("Sprinting")).to.equal(false)
		end)

		it("SetFlag called twice on the same key should remain idempotent", function()
			context:SetFlag("Jumping")
			context:SetFlag("Jumping")

			expect(context:HasFlag("Jumping")).to.equal(true)
		end)
	end)

	describe("FSMContext:Destroy", function()
		it("should clear all flags", function()
			local context = FSMContext.new(createDependencies())
			context:SetFlag("Jumping")

			context:Destroy()

			expect(context:HasFlag("Jumping")).to.equal(false)
		end)

		it("should not error when called with no flags set", function()
			local context = FSMContext.new(createDependencies())

			expect(function()
				context:Destroy()
			end).never.to.throw()
		end)
	end)

	describe("FSMContext module table", function()
		it("should be frozen", function()
			expect(function()
				(FSMContext :: any).SomeNewField = true
			end).to.throw()
		end)
	end)
end