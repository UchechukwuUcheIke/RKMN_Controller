--!strict
local MobileButtonPositioner = {}
MobileButtonPositioner.__index = MobileButtonPositioner

local TouchGamepadLayoutRegistry = require(script.Parent.TouchGamepadLayoutRegistry)
local TouchGamepadUI = require(script.Parent.UserInterface.TouchGamepadUI)

type ControlID = TouchGamepadLayoutRegistry.ControlID
type PositionableControl = TouchGamepadUI.PositionableControl
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout

type MobileButtonPositionerData = {
    _controls: {[ControlID]: PositionableControl}
}

export type MobileButtonPositioner = typeof(setmetatable({} :: MobileButtonPositionerData, MobileButtonPositioner))

function MobileButtonPositioner.new(): MobileButtonPositioner
    local self = setmetatable({}, MobileButtonPositioner)
    self._controls = {}
    return self :: MobileButtonPositioner
end

function MobileButtonPositioner.RegisterControl(self: MobileButtonPositioner, controlID: ControlID, control: PositionableControl): ()
    self._controls[controlID] = control
end

function MobileButtonPositioner.ApplyLayout(self: MobileButtonPositioner, layout: TouchGamepadLayout): ()
    for controlID in pairs(self._controls) do
        if not layout[controlID] then
            error(`Layout has no transform for {controlID}`)
        end
    end

    for controlID, control in pairs(self._controls) do
        control:SetTransform(layout[controlID])
    end
end

function MobileButtonPositioner.Destroy(self: MobileButtonPositioner): ()
    table.clear(self._controls)
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(MobileButtonPositioner)
return MobileButtonPositioner
