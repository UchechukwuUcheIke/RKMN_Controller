--!strict
local TouchGamepadUI = {}
TouchGamepadUI.__index = TouchGamepadUI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local ActionButtonModule = require(script.Parent.ActionButton)

type ActionID = InputAction.ActionID
type ActionButton = ActionButtonModule.ActionButton

type TouchGamepadUIData = {
    _screenGui: ScreenGui,
    _buttons: {[ActionID]: ActionButton}
}

export type TouchGamepadUI = typeof(setmetatable({} :: TouchGamepadUIData, TouchGamepadUI))

local BUTTON_LABELS: {[ActionID]: string} = {
    [InputAction.Left] = "<",
    [InputAction.Right] = ">",
    [InputAction.Jump] = "Jump",
    [InputAction.Dash] = "Dash",
    [InputAction.Shoot] = "Shoot",
}
-- Builds its own ScreenGui under `parent`, so nothing has to exist in Studio beforehand.
function TouchGamepadUI.new(parent: Instance): TouchGamepadUI
    local self = setmetatable({}, TouchGamepadUI)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TouchGamepad"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = parent

    self._screenGui = screenGui
    self._buttons = {}

    for _, actionName in pairs(InputAction) do
        self._buttons[actionName] = ActionButtonModule.new(actionName, BUTTON_LABELS[actionName], screenGui)
    end

    return self :: TouchGamepadUI
end

function TouchGamepadUI.GetButton(self: TouchGamepadUI, actionName: ActionID): ActionButton
    return self._buttons[actionName]
end

function TouchGamepadUI.SetVisible(self: TouchGamepadUI, isVisible: boolean): ()
    self._screenGui.Enabled = isVisible

    if not isVisible then
        for _, button in pairs(self._buttons) do
            button:ResetVisual()
        end
    end
end

function TouchGamepadUI.Destroy(self: TouchGamepadUI): ()
    for _, button in pairs(self._buttons) do
        button:Destroy()
    end
    table.clear(self._buttons)
    self._screenGui:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchGamepadUI)
return TouchGamepadUI
