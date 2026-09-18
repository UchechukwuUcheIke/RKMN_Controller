--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNController = ReplicatedStorage:WaitForChild("RKMNController")
local BaseState = require(RKMNController:WaitForChild("BaseState"))

return function()
	
	local function createFakeStateMachine(): any
		return {}
	end

	describe("BaseState.new", function()
		it("should set the Id passed in", function()
			local state = BaseState.new("Idle")
			expect(state.Id).to.equal("Idle")
		end)

		it("should return a distinct table for each call", function()
			local first = BaseState.new("Idle")
			local second = BaseState.new("Idle")

			expect(first).never.to.equal(second)
		end)

		it("should route method lookups through BaseState via its metatable", function()
			local state = BaseState.new("Idle")

			expect(state.OnEnter).to.equal(BaseState.OnEnter)
			expect(state.OnStep).to.equal(BaseState.OnStep)
			expect(state.OnExit).to.equal(BaseState.OnExit)
		end)
	end)

	describe("BaseState lifecycle methods", function()
		local state
		local fsm

		beforeEach(function()
			state = BaseState.new("Idle")
			fsm = createFakeStateMachine()
		end)

		it("OnEnter should be callable without erroring", function()
			expect(function()
				state:OnEnter(fsm)
			end).never.to.throw()
		end)

		it("OnStep should be callable without erroring", function()
			expect(function()
				state:OnStep(fsm, 1 / 60)
			end).never.to.throw()
		end)

		it("OnExit should be callable without erroring", function()
			expect(function()
				state:OnExit(fsm)
			end).never.to.throw()
		end)

	end)

	describe("BaseState module table", function()
		it("should be frozen so subclasses can't accidentally mutate shared defaults", function()
			expect(function()
				(BaseState :: any).SomeNewField = true
			end).to.throw()
		end)
	end)

	describe("subclassing via metatable chaining", function()
		it("should allow a subclass to override a lifecycle method", function()
			local CustomState = setmetatable({}, { __index = BaseState })
			CustomState.__index = CustomState

			local entered = false
			function CustomState.OnEnter(self, stateMachine)
				entered = true
			end

			local state = setmetatable(BaseState.new("Custom"), CustomState)
			local fsm = createFakeStateMachine()

			state:OnEnter(fsm)

			expect(entered).to.equal(true)
			expect(state.Id).to.equal("Custom")
		end)

	end)
end