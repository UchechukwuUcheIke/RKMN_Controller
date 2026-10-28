--!strict
local MobileButtonPositioner = {}
MobileButtonPositioner.__index = MobileButtonPositioner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local TouchGamepadLayoutRegistry = require(script.Parent.TouchGamepadLayoutRegistry)
local ActionButtonModule = require(script.Parent.UserInterface.ActionButton)

type ActionID = InputAction.ActionID
type ActionButton = ActionButtonModule.ActionButton
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout

type MobileButtonPositionerData = {
    _buttons: {[ActionID]: ActionButton}
}

export type MobileButtonPositioner = typeof(setmetatable({} :: MobileButtonPositionerData, MobileButtonPositioner))

function MobileButtonPositioner.new(): MobileButtonPositioner
    local self = setmetatable({}, MobileButtonPositioner)
    self._buttons = {}
    return self :: MobileButtonPositioner
end

function MobileButtonPositioner.RegisterButton(self: MobileButtonPositioner, actionName: ActionID, button: ActionButton): ()
    self._buttons[actionName] = button
end

function MobileButtonPositioner.ApplyLayout(self: MobileButtonPositioner, layout: TouchGamepadLayout): ()
    for actionName in pairs(self._buttons) do
        if not layout[actionName] then
            error(`Layout has no transform for {actionName}`)
        end
    end

    for actionName, button in pairs(self._buttons) do
        button:SetTransform(layout[actionName])
    end
end

function MobileButtonPositioner.Destroy(self: MobileButtonPositioner): ()
    table.clear(self._buttons)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(MobileButtonPositioner)
return MobileButtonPositioner
