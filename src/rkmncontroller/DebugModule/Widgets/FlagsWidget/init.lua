--!strict
local FlagsWidget = {}
FlagsWidget.__index = FlagsWidget

local RunService = game:GetService("RunService")
local WidgetsFolder = script.Parent
local DataRow = require(WidgetsFolder.DataRow)

type DataRow = DataRow.DataRow

type FlagsWidgetData = {
    IsMounted: boolean,
    _canvas: Frame,
    _flagRows: { [string]: DataRow }
}

type FlagsWidgetPrototype = typeof(FlagsWidget)

export type FlagsWidget = typeof(setmetatable(
    {} :: FlagsWidgetData,
    {} :: FlagsWidgetPrototype
))

function FlagsWidget.new(): FlagsWidget
    local data = {
        IsMounted = false,
        _flagRows = {},
    } :: FlagsWidgetData

    local self = setmetatable(data, FlagsWidget)
    self:_createUI()

    return self
end

function FlagsWidget._createUI(self: FlagsWidget): ()
    self._canvas = Instance.new("Frame")
    self._canvas.Name = "FlagsWidget"
    self._canvas.BackgroundTransparency = 1
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Parent = self._canvas
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    listLayout.VerticalFlex = Enum.UIFlexAlignment.None
end

function FlagsWidget.MountTo(self: FlagsWidget, layerCollector: Instance)
    self._canvas.Parent = layerCollector
    self.IsMounted = true
end

function FlagsWidget.Render(self: FlagsWidget, flags: { [string]: any })
    -- 1. Update existing flags and create new ones
    for flagName, flagValue in pairs(flags) do
        local row = self._flagRows[flagName]
        
        -- If we've never seen this flag before, create a DataRow for it
        if not row then
            row = DataRow.new(flagName, tostring(flagValue))
            row:MountTo(self._canvas)
            -- Hack to rename the row so UIListLayout sorts it alphabetically
            row._container.Name = flagName 
            self._flagRows[flagName] = row
        end
        
        -- Update the value
        row:UpdateValue(tostring(flagValue))
    end
end

function FlagsWidget:Destroy()
    for _, row in pairs(self._flagRows) do
        row:Destroy()
    end
    table.clear(self._flagRows)
    self._canvas:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

return FlagsWidget