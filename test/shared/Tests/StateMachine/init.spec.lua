--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage:WaitForChild("RKMNController")
local JestGlobals = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("JestGlobals"))
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local jest = JestGlobals.jest

local MockUtils = require(script.Parent.Parent.Parent.TestUtils.MockUtils)
local FSMContext = require(RKMNControllerFolder.FSMContext)
local StateMachine = require(RKMNControllerFolder.StateMachine)
local BaseState = require(RKMNControllerFolder.BaseState)

local createMockClass = MockUtils.createMockClass

type MethodMap = MockUtils.MethodMap
type MockResult<T> = MockUtils.MockResult<T>
type FSMContext = FSMContext.FSMContext
type BaseState = BaseState.BaseState
type StateMachine = StateMachine.StateMachine

const IDLE_STATE_NAME = "Idle"

local function createMockContext(): FSMContext
	local mockResult: MockResult<FSMContext> = createMockClass(FSMContext)
    local mockedInstance: FSMContext = mockResult.Instance
    return mockedInstance
end

local function createMockState(overrides: { [string]: any }?): BaseState
    local mockResult: MockResult<BaseState> = createMockClass(BaseState)
    local mockedInstance: BaseState = mockResult.Instance

	if overrides then
		for key, value in pairs(overrides) do
			mockedInstance[key] = value
		end
	end

	return mockedInstance
end

describe("StateMachine.new", function()
    local context: FSMContext
    local stateMachine: StateMachine

    beforeEach(function()
		context = createMockContext()
        stateMachine =  StateMachine.new(context)
	end)

    afterEach(function()
		context:Destroy()
        stateMachine:Destroy()
	end)

	it("initializes with the given context and empty state fields", function()
		expect(stateMachine.Context).toBe(context)
		expect(stateMachine.CurrentStateId).toBeNil()
		expect(stateMachine.CurrentState).toBeNil()
		expect(stateMachine.States).toEqual({})
	end)

	it("creates a usable OnStateChanged signal", function()
		expect(stateMachine.OnStateChanged).never.toBeNil()
        local functionType: string = "function"
		expect(type(stateMachine.OnStateChanged.Connect)).toBe(functionType)
		expect(type(stateMachine.OnStateChanged.Fire)).toBe(functionType)
	end)
end)


describe("StateMachine.RegisterState", function()
    local context: FSMContext
    local stateMachine: StateMachine

    beforeEach(function()
		context = createMockContext()
        stateMachine = StateMachine.new(context)
	end)

    afterEach(function()
		context:Destroy()
        stateMachine:Destroy()
	end)

	it("adds a state under the given id", function()
		local idleState = createMockState()

		stateMachine:RegisterState("Idle", idleState)

		expect(stateMachine.States.Idle).toBe(idleState)
	end)

	it("does not clobber other previously registered states", function()
		local idleState = createMockState()
		local walkState = createMockState()

		stateMachine:RegisterState("Idle", idleState)
		stateMachine:RegisterState("Walk", walkState)

		expect(stateMachine.States.Idle).toBe(idleState)
		expect(stateMachine.States.Walk).toBe(walkState)
	end)

	it("overwrites a state already registered under the same id", function()
		local firstState = createMockState()
		local secondState = createMockState()

        const stateName: string = "Idle"
		stateMachine:RegisterState(stateName, firstState)
		stateMachine:RegisterState(stateName, secondState)

		expect(stateMachine.States.Idle).toBe(secondState)
	end)
end)


describe("StateMachine.SetStates", function()
    local context: FSMContext
    local stateMachine: StateMachine

    beforeEach(function()
		context = createMockContext()
        stateMachine = StateMachine.new(context)
	end)

    afterEach(function()
		context:Destroy()
        stateMachine:Destroy()
	end)

	it("replaces the entire States table", function()
        local mockState: BaseState = createMockState()
		stateMachine:RegisterState("Stale", mockState)

		local idleState = createMockState()
		local walkState = createMockState()
		stateMachine:SetStates({
			Idle = idleState,
			Walk = walkState,
		})

		expect(stateMachine.States.Stale).toBeNil()
		expect(stateMachine.States.Idle).toBe(idleState)
		expect(stateMachine.States.Walk).toBe(walkState)
	end)
end)


describe("StateMachine.ChangeState", function()
    local context: FSMContext
    local stateMachine: StateMachine

    beforeEach(function()
		context = createMockContext()
        stateMachine = StateMachine.new(context)
	end)

    afterEach(function()
		context:Destroy()
        stateMachine:Destroy()
	end)

    local function createMockState(overrides: { [string]: any }?): MockResult<BaseState>
        local mockResult: MockResult<BaseState> = createMockClass(BaseState)
        local mockedInstance: BaseState = mockResult.Instance

        if overrides then
            for key, value in pairs(overrides) do
                mockedInstance[key] = value
            end
        end

        return mockResult
    end


	it("throws when the target state was never registered", function()
		expect(function()
			stateMachine:ChangeState("Missing")
		end).toThrow("State not found: Missing")
	end)

	it("enters the new state and updates CurrentStateId / CurrentState", function()
		local idleState = createMockState().Instance
        const stateName = "Idle"
		stateMachine:RegisterState(stateName, idleState)

		stateMachine:ChangeState(stateName)

		expect(stateMachine.CurrentStateId).toBe(stateName)
		expect(stateMachine.CurrentState).toBe(idleState)
		expect(idleState.OnEnter).toHaveBeenCalledTimes(1)
		expect(idleState.OnEnter).toHaveBeenCalledWith(idleState, stateMachine)
	end)

	it("exits the previous state before entering the new one", function()
		local idleState = createMockState().Instance
		local walkState = createMockState().Instance

        const idleStateName = "Idle"
        const walkStateName = "Walk"
		stateMachine:RegisterState(idleStateName, idleState)
		stateMachine:RegisterState(walkStateName, walkState)

		stateMachine:ChangeState(idleStateName)
		stateMachine:ChangeState(walkStateName)

		expect(idleState.OnExit).toHaveBeenCalledTimes(1)
		expect(idleState.OnExit).toHaveBeenCalledWith(idleState, stateMachine)
		expect(walkState.OnEnter).toHaveBeenCalledTimes(1)
	end)

	it("records the previous state id on the context", function()
        local idleState = createMockState().Instance
		local walkState = createMockState().Instance

        const idleStateName = "Idle"
        const walkStateName = "Walk"

		stateMachine:RegisterState(idleStateName, idleState)
		stateMachine:RegisterState(walkStateName, walkState)

		stateMachine:ChangeState(idleStateName)
		expect(context.PreviousStateId).toBeNil()

		stateMachine:ChangeState(walkStateName)
		expect(context.PreviousStateId).toBe(idleStateName)
	end)

	it("fires OnStateChanged with the new state id", function()
        const idleStateName: string = "Idle"
        local idleState: BaseState = createMockState().Instance
		stateMachine:RegisterState(idleStateName, idleState)

		local listener = jest.fn()
		stateMachine.OnStateChanged:Connect(listener)

		stateMachine:ChangeState(idleStateName)

		expect(listener).toHaveBeenCalledTimes(1)
		expect(listener).toHaveBeenCalledWith(idleStateName)
	end)

	it("is a no-op when changing to the currently active state", function()
		local idleStateMockResult: MockResult<BaseState> = createMockState()
        local idleState = idleStateMockResult.Instance
        const idleStateName: string = "Idle"
		stateMachine:RegisterState(idleStateName, idleState)
        stateMachine:ChangeState(idleStateName)

		-- Reset call counts recorded from the initial transition above.
        local idleStateMockMethods = idleStateMockResult.Mocks
		idleStateMockMethods["OnEnter"].mockClear()
		idleStateMockMethods["OnExit"].mockClear()
		local listener = jest.fn()
		stateMachine.OnStateChanged:Connect(listener)

		stateMachine:ChangeState("Idle")

		expect(idleState.OnEnter).never.toHaveBeenCalled()
		expect(idleState.OnExit).never.toHaveBeenCalled()
		expect(listener).never.toHaveBeenCalled()
		expect(stateMachine.CurrentStateId).toBe("Idle")
	end)

	it("does not call OnExit on the first transition (no previous state)", function()
		const idleState: BaseState = createMockState().Instance

        const idleStateName: string = "Idle"
		stateMachine:RegisterState(idleStateName, idleState :: any)
		stateMachine:ChangeState(idleStateName)

		expect(idleState.OnExit).never.toHaveBeenCalled()
	end)
end)


describe("StateMachine.Update", function()
    local context: FSMContext
    local stateMachine: StateMachine

    beforeEach(function()
		context = createMockContext()
        stateMachine = StateMachine.new(context)
	end)

    afterEach(function()
		context:Destroy()
        stateMachine:Destroy()
	end)

	it("forwards dt to the current state's OnStep with the machine as self", function()
		const idleState: BaseState = createMockState()
        const idleStateName: string = "Idle"
		stateMachine:RegisterState(idleStateName, idleState :: any)
		stateMachine:ChangeState(idleStateName)

        const delta: number = 0.5
		stateMachine:Update(delta)

		expect(idleState.OnStep).toHaveBeenCalledTimes(1)
		expect(idleState.OnStep).toHaveBeenCalledWith(idleState, stateMachine, delta)
	end)

	it("does nothing when the current state has no OnStep hook", function()
        const idleStateName: string = "Idle"
        const idleState: BaseState = ({} :: any) :: BaseState
		stateMachine:RegisterState(idleStateName, idleState)
		stateMachine:ChangeState(idleStateName)

		expect(function()
			stateMachine:Update(1/60)
		end).never.toThrow()
	end)
end)


describe("StateMachine.Destroy", function()
    local context: FSMContext
    local stateMachine: StateMachine

    beforeEach(function()
		context = createMockContext()
        stateMachine = StateMachine.new(context :: FSMContext)
	end)


	it("Destroys the context and clears States", function()
		stateMachine:RegisterState(IDLE_STATE_NAME, createMockState() :: any)

		stateMachine:Destroy()

		expect(context.Destroy).toHaveBeenCalledTimes(1)
		expect(next(stateMachine.States)).toBeNil()
	end)
end)