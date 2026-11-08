--!strict
local TouchGamepadUI = {}
TouchGamepadUI.__index = TouchGamepadUI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local TouchGamepadLayoutRegistry = require(script.Parent.Parent.TouchGamepadLayoutRegistry)
local ActionButtonModule = require(script.Parent.ActionButton)
local DPadModule = require(script.Parent.DPad)

type ActionID = InputAction.ActionID
type ControlID = TouchGamepadLayoutRegistry.ControlID
type ButtonTransform = TouchGamepadLayoutRegistry.ButtonTransform
type ActionButton = ActionButtonModule.ActionButton
type ButtonShape = ActionButtonModule.ButtonShape
type DPad = DPadModule.DPad

-- Anything the layout can place: a lone button, or the pad holding Left and Right.
export type PositionableControl = {
    SetTransform: (self: any, transform: ButtonTransform) -> (),
    GetInstance: (self: any) -> GuiObject
}

type TouchGamepadUIData = {
    _screenGui: ScreenGui,
    _dPad: DPad,
    _buttons: {[ActionID]: ActionButton}
}

export type TouchGamepadUI = typeof(setmetatable({} :: TouchGamepadUIData, TouchGamepadUI))

local BUTTON_LABELS: {[ActionID]: string} = {
    [InputAction.Jump] = "Jump",
    [InputAction.Dash] = "Dash",
    [InputAction.Shoot] = "Shoot",
    [InputAction.Menu] = "Menu",
}

local BUTTON_SHAPES: {[ActionID]: ButtonShape} = {
    [InputAction.Jump] = "Circle",
    [InputAction.Dash] = "Circle",
    [InputAction.Shoot] = "Circle",
    [InputAction.Menu] = "Rounded",
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
    self._dPad = DPadModule.new(screenGui)
    self._buttons = {
        [InputAction.Left] = self._dPad:GetLeftButton(),
        [InputAction.Right] = self._dPad:GetRightButton(),
    }

    for actionName, label in pairs(BUTTON_LABELS) do
        self._buttons[actionName] = ActionButtonModule.new(actionName, label, screenGui, BUTTON_SHAPES[actionName])
    end

    return self :: TouchGamepadUI
end

function TouchGamepadUI.GetButton(self: TouchGamepadUI, actionName: ActionID): ActionButton
    return self._buttons[actionName]
end

-- What the layout places: the pad as one control, and every other button on its own.
function TouchGamepadUI.GetPositionableControls(self: TouchGamepadUI): {[ControlID]: PositionableControl}
    local controls: {[ControlID]: PositionableControl} = {
        [TouchGamepadLayoutRegistry.DPad] = self._dPad
    }

    for actionName in pairs(BUTTON_LABELS) do
        controls[actionName] = self._buttons[actionName]
    end

    return controls
end

function TouchGamepadUI.SetDisplayOrder(self: TouchGamepadUI, displayOrder: number): ()
    self._screenGui.DisplayOrder = displayOrder
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
    self._dPad:Destroy()
    for actionName in pairs(BUTTON_LABELS) do
        self._buttons[actionName]:Destroy()
    end
    table.clear(self._buttons)
    self._screenGui:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchGamepadUI)
return TouchGamepadUI
