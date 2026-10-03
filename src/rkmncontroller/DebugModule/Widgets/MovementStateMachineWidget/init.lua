--!strict
local MovementStateMachineWidget = {}
MovementStateMachineWidget.__index = MovementStateMachineWidget

local WidgetsFolder = script.Parent
local DataRow = require(WidgetsFolder.DataRow)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)

type MovementStateMachine = MovementStateMachine.MovementStateMachine
type DataRow = DataRow.DataRow

type MovementStateMachineWidgetData = {
    IsMounted: boolean,
    _stateMachine: MovementStateMachine,
    _canvas: Frame,
    _currentStateRow: DataRow,
    _previousStateRow: DataRow
}

type MovementStateMachineWidgetPrototype = typeof(MovementStateMachineWidget)

export type MovementStateMachineWidget = typeof(setmetatable(
    {} :: MovementStateMachineWidgetData,
    {} :: MovementStateMachineWidgetPrototype
))

function MovementStateMachineWidget.new(stateMachine: MovementStateMachine): MovementStateMachineWidget

    local data = {
        IsMounted = false,
        _stateMachine = stateMachine,
    } :: MovementStateMachineWidgetData

    local self = setmetatable(data, MovementStateMachineWidget)
    self:_createUI()

    return self
end

function MovementStateMachineWidget.MountTo(self: MovementStateMachineWidget, layerCollector: Instance)
    self._canvas.Parent = layerCollector
    self.IsMounted = true
end

function MovementStateMachineWidget.Render(self: MovementStateMachineWidget)
    local currentState: string = tostring(self._stateMachine.CurrentStateId)
    self._currentStateRow:UpdateValue(currentState)
    local previousState: string = tostring(self._stateMachine.Context.PreviousStateId or "None")
    self._previousStateRow:UpdateValue(previousState)
end

function MovementStateMachineWidget:Destroy()
    self._currentStateRow:Destroy()
    self._previousStateRow:Destroy()
    self._canvas:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

function MovementStateMachineWidget._createDataRows(self: MovementStateMachineWidget): ()
    self._currentStateRow = DataRow.new("Current State", "None")
    self._currentStateRow:MountTo(self._canvas)
    
    self._previousStateRow = DataRow.new("Previous State", "None")
    self._previousStateRow:MountTo(self._canvas)
end

function MovementStateMachineWidget._createCanvas(self: MovementStateMachineWidget): ()
    self._canvas = Instance.new("Frame")
    self._canvas.Name = "MovementStateMachineWidget"
    self._canvas.BackgroundTransparency = 1
end

function MovementStateMachineWidget._createListLayout(self: MovementStateMachineWidget): ()
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    listLayout.VerticalFlex = Enum.UIFlexAlignment.None
    listLayout.Parent = self._canvas
end

function MovementStateMachineWidget._createUI(self: MovementStateMachineWidget): ()
    self:_createCanvas()
    self:_createListLayout()
    self:_createDataRows()
end

table.freeze(MovementStateMachine)

return MovementStateMachineWidget