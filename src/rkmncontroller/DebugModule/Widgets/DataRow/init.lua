--!strict
local DataRow = {}
DataRow.__index = DataRow

type DataRowData = {
    _canvas: Frame,
    _keyLabel: TextLabel,
    _valueLabel: TextLabel
}

type DataRowPrototype = typeof(DataRow)

export type DataRow = typeof(setmetatable(
    {} :: DataRowData,
    {} :: DataRowPrototype
))

function DataRow.new(labelText: string, initialValue: string): DataRow
    local self = setmetatable({}, DataRow) :: DataRow
    
    self:_createUI(labelText, initialValue)
    
    return self
end

function DataRow._createCanvas(self: DataRow, labelText: string): ()
    self._canvas = Instance.new("Frame")
    self._canvas.Name = "DataRow_" .. labelText
    self._canvas.BackgroundTransparency = 1
end

function DataRow._createKeyLabel(self: DataRow, labelText: string): ()
    self._keyLabel = Instance.new("TextLabel")
    self._keyLabel.Name = "KeyLabel"
    self._keyLabel.BackgroundTransparency = 1
    self._keyLabel.Font = Enum.Font.RobotoMono
    self._keyLabel.TextSize = 14
    self._keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._keyLabel.Text = labelText
    self._keyLabel.Parent = self._canvas
end

function DataRow._createValueLabel(self: DataRow, initialValue: string): ()
    self._valueLabel = Instance.new("TextLabel")
    self._valueLabel.Name = "ValueLabel"
    self._valueLabel.BackgroundTransparency = 1
    self._valueLabel.Font = Enum.Font.RobotoMono
    self._valueLabel.TextSize = 14
    self._valueLabel.TextColor3 = Color3.new(1, 1, 1)
    self._valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    self._valueLabel.Text = initialValue
    self._valueLabel.Parent = self._canvas
end

function DataRow._createUI(self: DataRow, labelText: string, initialValue: string): ()
    self:_createCanvas(labelText)
    self:_createKeyLabel(labelText)
    self:_createValueLabel(initialValue)
end

function DataRow.MountTo(self: DataRow, parent: Instance): ()
    self._canvas.Parent = parent
end

function DataRow.Dismount(self: DataRow): ()
    self._canvas.Parent = nil
end

function DataRow.UpdateValue(self: DataRow, newValue: string): ()
    if self._valueLabel.Text ~= newValue then
        self._valueLabel.Text = newValue
    end
end

function DataRow.Destroy(self: DataRow): ()
    self._canvas:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

function DataRow.GetValueText(self: DataRow): string
    return self._valueLabel.Text
end

function DataRow.GetKeyText(self: DataRow): string
    return self._keyLabel.Text
end

table.freeze(DataRow)

return DataRow