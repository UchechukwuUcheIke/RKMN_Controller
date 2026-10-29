--!strict
local ControlProfile = {}
ControlProfile.__index = ControlProfile

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)

local PlayerInputFolder = script.Parent
local InputAction = require(PlayerInputFolder.InputAction)
local InputDevice = require(PlayerInputFolder.InputDevice)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type InputDevice = InputDevice.InputDevice
type InputBinding = InputSchemeTypes.InputBinding
type Bindings = InputSchemeTypes.Bindings
type InputScheme = InputSchemeTypes.InputScheme

type ControlProfileData = {
    _defaultSchemes: {[InputDevice]: InputScheme},
    _customSchemes: {[InputDevice]: InputScheme},
    SchemeChanged: Signal
}

export type ControlProfile = typeof(setmetatable({} :: ControlProfileData, ControlProfile))

local function copyScheme(scheme: InputScheme): InputScheme
    local copy: InputScheme = {}

    for actionName, bindings in pairs(scheme) do
        local bindingsCopy: Bindings = {}
        for binding, isBound in pairs(bindings) do
            if isBound then
                bindingsCopy[binding] = true
            end
        end
        copy[actionName] = bindingsCopy
    end

    return copy
end

local function findActionForBinding(scheme: InputScheme, binding: InputBinding): ActionID?
    for actionName, bindings in pairs(scheme) do
        if bindings[binding] then
            return actionName
        end
    end

    return nil
end

local function removeBinding(scheme: InputScheme, actionName: ActionID, binding: InputBinding): ()
    local bindings = scheme[actionName]
    if not bindings then
        return
    end

    bindings[binding] = nil
    if next(bindings) == nil then
        scheme[actionName] = nil
    end
end

function ControlProfile.new(keyboardDefault: InputScheme, gamepadDefault: InputScheme): ControlProfile
    local self = setmetatable({}, ControlProfile)

    self._defaultSchemes = {
        [InputDevice.Keyboard] = keyboardDefault,
        [InputDevice.Gamepad] = gamepadDefault,
        [InputDevice.Touch] = {},
    }
    self._customSchemes = {}
    self.SchemeChanged = Signal.new()

    return self :: ControlProfile
end

-- Returns the live table: read it, never mutate it. Touch has no key bindings, so its scheme is always empty.
function ControlProfile.GetScheme(self: ControlProfile, device: InputDevice): InputScheme
    return self._customSchemes[device] or self._defaultSchemes[device]
end

-- Assigning a binding takes it from whichever action had it, leaving that action with one fewer binding.
function ControlProfile.BindKey(self: ControlProfile, device: InputDevice, actionName: ActionID, binding: InputBinding): ()
    self:_assertEditable(device)

    local currentBindings = self:GetScheme(device)[actionName]
    if currentBindings and currentBindings[binding] then
        return
    end

    local scheme = self:_getEditableScheme(device)

    local previousAction = findActionForBinding(scheme, binding)
    if previousAction then
        removeBinding(scheme, previousAction, binding)
    end

    local bindings = scheme[actionName]
    if not bindings then
        bindings = {}
        scheme[actionName] = bindings
    end
    bindings[binding] = true

    self.SchemeChanged:Fire(device)
end

function ControlProfile.UnbindKey(self: ControlProfile, device: InputDevice, actionName: ActionID, binding: InputBinding): ()
    self:_assertEditable(device)

    local currentBindings = self:GetScheme(device)[actionName]
    if not currentBindings or not currentBindings[binding] then
        return
    end

    removeBinding(self:_getEditableScheme(device), actionName, binding)

    self.SchemeChanged:Fire(device)
end

-- Drops the player's edits for one device, so it goes back to the live default.
function ControlProfile.ResetDevice(self: ControlProfile, device: InputDevice): ()
    if not self._customSchemes[device] then
        return
    end

    self._customSchemes[device] = nil

    self.SchemeChanged:Fire(device)
end

function ControlProfile._assertEditable(self: ControlProfile, device: InputDevice): ()
    if device == InputDevice.Touch then
        error("Touch has no key bindings to edit")
    end
end

function ControlProfile._getEditableScheme(self: ControlProfile, device: InputDevice): InputScheme
    local scheme = self._customSchemes[device]
    if not scheme then
        scheme = copyScheme(self._defaultSchemes[device])
        self._customSchemes[device] = scheme
    end

    return scheme
end

function ControlProfile.Destroy(self: ControlProfile): ()
    self.SchemeChanged:DisconnectAll()
    table.clear(self._customSchemes)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ControlProfile)
return ControlProfile
