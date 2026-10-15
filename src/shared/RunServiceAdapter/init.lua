local RunService = game:GetService("RunService")

local RunServiceAdapter = {}
RunServiceAdapter.__index = RunServiceAdapter
RunServiceAdapter.ClassName = "RunServiceAdapter"
RunServiceAdapter.Super = nil

type RunServiceAdapterData = {
	Class: typeof(RunServiceAdapter),
	_onStep: StepCallback,
	_isRunning: boolean,
	_bindName: string,
	_renderPriority: number,
}

export type StepCallback = (dt: number) -> ()

type RunServiceAdapterPrototype = typeof(RunServiceAdapter)

export type RunServiceAdapter = typeof(setmetatable(
	{} :: RunServiceAdapterData,
	{} :: RunServiceAdapterPrototype
))

function RunServiceAdapter.new(bindName: string, renderPriority: number, onStep: StepCallback): RunServiceAdapter
	local self = setmetatable({}, RunServiceAdapter)
	
	self.Class = RunServiceAdapter
	self._onStep = onStep
	self._isRunning = false
	self._bindName = bindName
	self._renderPriority = renderPriority
	
	return self
end

function RunServiceAdapter.IsA(self: RunServiceAdapter, className: string): boolean
	local currentClass: any = self.Class
	
	while currentClass do
		if currentClass.ClassName == className then
			return true
		end
		currentClass = currentClass.Super
	end
	
	return false
end

function RunServiceAdapter.Start(self: RunServiceAdapter): ()
	if self._isRunning then
		return
	end
	self._isRunning = true
	
	RunService:BindToRenderStep(self._bindName, self._renderPriority, self._onStep)
end

function RunServiceAdapter.Stop(self: RunServiceAdapter): ()
	if not self._isRunning then
		return
	end
	RunService:UnbindFromRenderStep(self._bindName)
	self._isRunning = false
end

function RunServiceAdapter.IsRunning(self: RunServiceAdapter): boolean
	return self._isRunning
end

function RunServiceAdapter.Destroy(self: RunServiceAdapter): ()
	self:Stop()
	setmetatable(self :: any, nil)
	table.freeze(self)
end

table.freeze(RunServiceAdapter)

return RunServiceAdapter