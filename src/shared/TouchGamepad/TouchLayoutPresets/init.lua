--!strict
local TouchGamepadLayoutRegistry = require(script.Parent.TouchGamepadLayoutRegistry)

type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout

export type LayoutPreset = {
    Id: string,
    Name: string,
    Layout: TouchGamepadLayout
}

local TouchLayoutPresets = {}

TouchLayoutPresets.StandardID = "Standard"

TouchLayoutPresets.All = table.freeze({
    table.freeze({
        Id = TouchLayoutPresets.StandardID,
        Name = "Standard",
        Layout = TouchGamepadLayoutRegistry.Standard,
    } :: LayoutPreset),
})

function TouchLayoutPresets.Find(presetID: string): LayoutPreset?
    for _, preset in ipairs(TouchLayoutPresets.All) do
        if preset.Id == presetID then
            return preset
        end
    end
    return nil
end

table.freeze(TouchLayoutPresets)
return TouchLayoutPresets
