--!strict
local InputMapper = {}
InputMapper.__index = InputMapper

local Signal = require(game:GetService("ReplicatedStorage"):WaitForChild("DevPackages"):WaitForChild("goodsignal"))
local PlayerInputFolder = script.Parent
local InputAction = require(PlayerInputFolder.InputAction)
local InputSchemeTypes = require(PlayerInputFolder.InputScheme)

type Signal = typeof(Signal)
type ActionID = InputAction.ActionID
type InputBinding = InputSchemeTypes.InputBinding
type Bindings = InputSchemeTypes.Bindings
type InputScheme = InputSchemeTypes.InputScheme

type InputMapperData = {
    _activeScheme: InputScheme,
    _keyToActionMap: {[InputBinding]: ActionID},
    InputSchemeChanged: Signal
}

export type InputMapper = typeof(setmetatable({} :: InputMapperData, InputMapper))

function InputMapper.new(): InputMapper
    local self = setmetatable({}, InputMapper)

    self._activeScheme = {}
    self._keyToActionMap = {}
    self.InputSchemeChanged = Signal.new()

    return self :: InputMapper
end

function InputMapper.LoadControlScheme(self: InputMapper, newScheme: InputScheme): ()
    local scheme: InputScheme = {}
    local keyToActionMap: {[InputBinding]: ActionID} = {}

    for actionName, bindings in pairs(newScheme) do
        local actionBindings: Bindings = {}

        for inputEnum, isBound in pairs(bindings) do
            if not isBound then
                continue
            end

            local existingAction = keyToActionMap[inputEnum]
            if existingAction then
                error(`{inputEnum} is bound to both {existingAction} and {actionName}`)
            end

            actionBindings[inputEnum] = true
            keyToActionMap[inputEnum] = actionName 
        end

        scheme[actionName] = actionBindings
    end

    self._activeScheme = scheme
    self._keyToActionMap = keyToActionMap

    self.InputSchemeChanged:Fire(self._activeScheme)
end

function InputMapper.BindKeyToAction(self: InputMapper, actionName: ActionID, inputEnum: InputBinding): ()
    local previousAction: ActionID = self._keyToActionMap[inputEnum]
    if previousAction == actionName then
        return
    end

    if previousAction then
        self:_removeBinding(previousAction, inputEnum)
    end

    local bindings = self._activeScheme[actionName]
    if not bindings then
        bindings = {}
        self._activeScheme[actionName] = bindings
    end

    bindings[inputEnum] = true
    self._keyToActionMap[inputEnum] = actionName

    self.InputSchemeChanged:Fire(self._activeScheme)
end

function InputMapper.UnbindKeyFromAction(self: InputMapper, actionName: ActionID, inputEnum: InputBinding): ()
    if self._keyToActionMap[inputEnum] ~= actionName then
        return
    end

    self:_removeBinding(actionName, inputEnum)

    self.InputSchemeChanged:Fire(self._activeScheme)
end

function InputMapper._removeBinding(self: InputMapper, actionName: ActionID, inputEnum: InputBinding): ()
    local bindings = self._activeScheme[actionName]
    if bindings then
        bindings[inputEnum] = nil
        if next(bindings) == nil then
            self._activeScheme[actionName] = nil
        end
    end

    self._keyToActionMap[inputEnum] = nil
end

function InputMapper.GetActionForKey(self: InputMapper, inputEnum: InputBinding): ActionID?
    return self._keyToActionMap[inputEnum]
end

function InputMapper.GetKeysForAction(self: InputMapper, actionName: ActionID): Bindings?
    return self._activeScheme[actionName]
end

function InputMapper.Destroy(self: InputMapper): ()
    self.InputSchemeChanged:DisconnectAll()
    table.clear(self._activeScheme)
    table.clear(self._keyToActionMap)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(InputMapper)
return InputMapper
