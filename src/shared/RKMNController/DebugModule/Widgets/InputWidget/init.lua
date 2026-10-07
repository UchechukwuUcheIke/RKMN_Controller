--!strict
local InputWidget = {}
InputWidget.__index = InputWidget

local RunService = game:GetService("RunService")
local WidgetsFolder = script.Parent
local DataRow = require(WidgetsFolder.DataRow)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local InputController = require(RKMNControllerFolder.InputController) 

type InputController = InputController.InputController
type DataRow = DataRow.DataRow

type InputWidgetData = {
    IsMounted: boolean,
    _inputController: InputController,
    _canvas: Frame,
    _moveDirectionRow: DataRow,
    _isHoldingJumpRow: DataRow
}

type InputWidgetPrototype = typeof(InputWidget)

export type InputWidget = typeof(setmetatable(
    {} :: InputWidgetData,
    {} :: InputWidgetPrototype
))

function InputWidget.new(inputController: InputController): InputWidget
    local data = {
        IsMounted = false,
        _inputController = inputController,
    } :: InputWidgetData

    local self = setmetatable(data, InputWidget)
    self:_createUI()

    return self
end

function InputWidget.MountTo(self: InputWidget, layerCollector: Instance)
    self._canvas.Parent = layerCollector
    self.IsMounted = true
end

function InputWidget.Dismount(self: InputWidget)
    self._canvas.Parent = mil
    self.IsMounted = true
end

function InputWidget.Render(self: InputWidget)
    self._moveDirectionRow:UpdateValue(tostring(self._inputController.MoveDirection))
    self._isHoldingJumpRow:UpdateValue(tostring(self._inputController.IsHoldingJump))
end

function InputWidget.Destroy(self: InputWidget)
    self._moveDirectionRow:Destroy()
    self._isHoldingJumpRow:Destroy()
    self._canvas:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

function InputWidget._createUI(self: InputWidget): ()
    self:_createCanvas()
    self:_createListLayout()
    self:_createDataRows()
end

function InputWidget._createDataRows(self: InputWidget): ()
    self._moveDirectionRow = DataRow.new("Move Direction", "0")
    self._moveDirectionRow:MountTo(self._canvas)
    
    self._isHoldingJumpRow = DataRow.new("Holding Jump", "false")
    self._isHoldingJumpRow:MountTo(self._canvas)
end

function InputWidget._createCanvas(self: InputWidget): ()
    self._canvas = Instance.new("Frame")
    self._canvas.Name = "InputWidget"
    self._canvas.BackgroundTransparency = 1
end

function InputWidget._createListLayout(self: InputWidget): ()
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    listLayout.VerticalFlex = Enum.UIFlexAlignment.None
    listLayout.Parent = self._canvas
end

table.freeze(InputWidget)

return InputWidget