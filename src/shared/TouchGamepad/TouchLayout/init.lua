--!strict
local TouchLayout = {}
TouchLayout.__index = TouchLayout

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local ButtonTransformModule = require(script.Parent.ButtonTransform)

export type ControlID = "DPad" | InputAction.ActionID

type ButtonTransform = ButtonTransformModule.ButtonTransform

type TouchLayoutData = {
    _transforms: {[ControlID]: ButtonTransform}
}

export type TouchLayout = typeof(setmetatable({} :: TouchLayoutData, TouchLayout))

function TouchLayout.new(transforms: {[ControlID]: ButtonTransform}): TouchLayout
    local self = setmetatable({}, TouchLayout)

    local copy: {[ControlID]: ButtonTransform} = {}
    for controlID, transform in pairs(transforms) do
        copy[controlID] = transform
    end
    self._transforms = table.freeze(copy)

    return table.freeze(self) :: TouchLayout
end

function TouchLayout.HasControl(self: TouchLayout, controlID: ControlID): boolean
    return self._transforms[controlID] ~= nil
end

function TouchLayout.GetTransform(self: TouchLayout, controlID: ControlID): ButtonTransform?
    return self._transforms[controlID]
end

function TouchLayout.GetControlIDs(self: TouchLayout): {ControlID}
    local controlIDs: {ControlID} = {}
    for controlID in pairs(self._transforms) do
        table.insert(controlIDs, controlID)
    end
    return controlIDs
end

-- A new layout that shares every transform it did not replace.
function TouchLayout.CopyWithTransform(self: TouchLayout, controlID: ControlID, transform: ButtonTransform): TouchLayout
    if not self:HasControl(controlID) then
        error(`Layout has no control {controlID}`)
    end

    local transforms: {[ControlID]: ButtonTransform} = {}
    for otherID, otherTransform in pairs(self._transforms) do
        transforms[otherID] = otherTransform
    end
    transforms[controlID] = transform

    return TouchLayout.new(transforms)
end

-- True when `other` places every control this layout places, and possibly more.
function TouchLayout.HasAllControlsOf(self: TouchLayout, other: TouchLayout): boolean
    for _, controlID in ipairs(other:GetControlIDs()) do
        if not self:HasControl(controlID) then
            return false
        end
    end
    return true
end

-- Two layouts are equal when they place the same controls with equal transforms.
function TouchLayout.Equals(self: TouchLayout, other: TouchLayout): boolean
    if not (self:HasAllControlsOf(other) and other:HasAllControlsOf(self)) then
        return false
    end

    for controlID, transform in pairs(self._transforms) do
        if not transform:Equals(other._transforms[controlID]) then
            return false
        end
    end
    return true
end

table.freeze(TouchLayout)
return TouchLayout
