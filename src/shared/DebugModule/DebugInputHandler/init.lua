--!strict
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DevPackages = ReplicatedStorage.DevPackages
local Signal = require(DevPackages.goodsignal)

local DebuggerFolder = script.Parent
local KeyBindings = require(DebuggerFolder.KeyBindings)

local DebugInputHandler = {}
DebugInputHandler.__index = DebugInputHandler

type Signal = typeof(Signal)

type InputHandlerData = {
	OnPauseToggled: Signal,
    OnStepForward: Signal,
    _inputConnection: RBXScriptConnection?
}

type InputHandlerPrototype = typeof(DebugInputHandler)

type KeyBindings = KeyBindings.KeyBindings

export type InputHandler = typeof(setmetatable(
	{} :: InputHandlerData,
	{} :: InputHandlerPrototype
))

function DebugInputHandler.new(): InputHandler
	local self = setmetatable({}, DebugInputHandler)
	
	self.OnPauseToggled = Signal.new()
	self.OnStepForward = Signal.new()
	self._inputConnection = nil :: RBXScriptConnection?
	
	return self
end

function checkIsKeyPressed(keyCode: Enum.KeyCode, keyBindings: KeyBindings): boolean
    return keyBindings[keyCode] ~= nil
end

function DebugInputHandler._handleInputBegan(self: InputHandler, input: InputObject, gameProcessed: boolean): ()
    if gameProcessed then
        return
    end
		
	if checkIsKeyPressed(input.KeyCode, KeyBindings.Pause) then
		self.OnPauseToggled:Fire()
	elseif checkIsKeyPressed(input.KeyCode, KeyBindings.StepForward) then
		self.OnStepForward:Fire()
	end
end

function DebugInputHandler.Enable(self: InputHandler): ()
	if self._inputConnection then
        return
    end
	
	self._inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		self:_handleInputBegan(input, gameProcessed)
	end)
end

function DebugInputHandler.Disable(self: InputHandler): ()
	if not self._inputConnection then
		return
	end

    self._inputConnection:Disconnect()
	self._inputConnection = nil
end

function DebugInputHandler.Destroy(self: InputHandler): ()
	self:Disable()
	self.OnPauseToggled:Destroy()
	self.OnStepForward:Destroy()
end

return DebugInputHandler

