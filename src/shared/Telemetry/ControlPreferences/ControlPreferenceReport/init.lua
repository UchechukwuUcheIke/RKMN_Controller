--!strict
local ControlPreferenceReport = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputDevice = require(ReplicatedStorage.Data.InputDevice)
local InputSchemeTypes = require(ReplicatedStorage.PlayerInput.InputScheme)
local TouchGamepadLayoutRegistry = require(ReplicatedStorage.TouchGamepad.TouchGamepadLayoutRegistry)

type InputDevice = InputDevice.InputDevice
type InputScheme = InputSchemeTypes.InputScheme
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout

export type BindingEntry = {
    Action: string,
    Binding: string
}

export type TouchControlEntry = {
    Control: string,
    PositionScaleX: number,
    PositionScaleY: number,
    BaseSizeX: number,
    BaseSizeY: number,
    Scale: number,
    Transparency: number,
}

export type ControlPreferenceReport = {
    Device: InputDevice,
    Bindings: {BindingEntry},
    TouchControls: {TouchControlEntry}
}

local function makeReport(device: InputDevice, bindings: {BindingEntry}, touchControls: {TouchControlEntry}): ControlPreferenceReport
    return table.freeze({
        Device = device,
        Bindings = table.freeze(bindings),
        TouchControls = table.freeze(touchControls),
    })
end

local function sortBindingEntry(first: BindingEntry, second: BindingEntry): boolean
    if first.Action ~= second.Action then
        return first.Action < second.Action
    end
    return first.Binding < second.Binding
end

local function getBindingsFromScheme(scheme: InputScheme): {BindingEntry}
    local bindings: {BindingEntry} = {}
    for actionName, boundInputs in pairs(scheme) do
        for binding, isBound in pairs(boundInputs) do
            if isBound then
                table.insert(bindings, table.freeze({ Action = actionName, Binding = binding.Name }))
            end
        end
    end

    return bindings
end

function ControlPreferenceReport.FromInputScheme(device: InputDevice, scheme: InputScheme): ControlPreferenceReport
    assert(device ~= InputDevice.Touch, "A touch report comes from a layout, not a scheme")

    local bindings = getBindingsFromScheme(scheme)

    table.sort(bindings, sortBindingEntry)

    return makeReport(device, bindings, {})
end

function getControlTransformsFromTouchLayout(layout: TouchGamepadLayout): {TouchControlEntry}
    local touchControls: {TouchControlEntry} = {}
    for _, controlID in ipairs(layout:GetControlIDs()) do
        local transform = layout:GetTransform(controlID)
        if transform then
            table.insert(touchControls, table.freeze({
                Control = controlID,
                PositionScaleX = transform.Position.X.Scale,
                PositionScaleY = transform.Position.Y.Scale,
                BaseSizeX = transform.BaseSize.X.Offset,
                BaseSizeY = transform.BaseSize.Y.Offset,
                Scale = transform.Scale,
                Transparency = transform.Transparency
            }))
        end
    end

    return touchControls
end

local function sortTouchControlEntry(first: TouchControlEntry, second: TouchControlEntry): boolean
    return first.Control < second.Control
end

function ControlPreferenceReport.FromTouchLayout(layout: TouchGamepadLayout): ControlPreferenceReport
    local touchControls = getControlTransformsFromTouchLayout(layout)

    table.sort(touchControls, sortTouchControlEntry)

    return makeReport(InputDevice.Touch, {}, touchControls)
end

table.freeze(ControlPreferenceReport)
return ControlPreferenceReport
