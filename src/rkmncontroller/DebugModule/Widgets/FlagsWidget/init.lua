--!strict
local FlagsWidget = {}
FlagsWidget.__index = FlagsWidget

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
    -- TODO
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