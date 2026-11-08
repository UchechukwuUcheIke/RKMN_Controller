--!strict
local TouchLayoutProfile = {}
TouchLayoutProfile.__index = TouchLayoutProfile

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)

local LayoutRegistry = require(script.Parent.TouchGamepadLayoutRegistry)

type Signal = typeof(Signal)
type TouchGamepadLayout = LayoutRegistry.TouchGamepadLayout

type TouchLayoutProfileData = {
    _defaultLayout: TouchGamepadLayout,
    _customLayout: TouchGamepadLayout?,
    LayoutChanged: Signal
}

export type TouchLayoutProfile = typeof(setmetatable({} :: TouchLayoutProfileData, TouchLayoutProfile))

function TouchLayoutProfile.new(defaultLayout: TouchGamepadLayout): TouchLayoutProfile
    local self = setmetatable({}, TouchLayoutProfile)

    self._defaultLayout = defaultLayout
    self._customLayout = nil
    self.LayoutChanged = Signal.new()

    return self :: TouchLayoutProfile
end

function TouchLayoutProfile.GetLayout(self: TouchLayoutProfile): TouchGamepadLayout
    return self._customLayout or self._defaultLayout
end

function TouchLayoutProfile.SetLayout(self: TouchLayoutProfile, layout: TouchGamepadLayout): ()
    for _, controlID in ipairs(self._defaultLayout:GetControlIDs()) do
        if not layout:HasControl(controlID) then
            error(`Layout has no transform for {controlID}`)
        end
    end

    self._customLayout = layout

    self.LayoutChanged:Fire()
end

function TouchLayoutProfile.ResetLayout(self: TouchLayoutProfile): ()
    if not self._customLayout then
        return
    end

    self._customLayout = nil

    self.LayoutChanged:Fire()
end

function TouchLayoutProfile.Destroy(self: TouchLayoutProfile): ()
    self.LayoutChanged:DisconnectAll()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchLayoutProfile)
return TouchLayoutProfile
