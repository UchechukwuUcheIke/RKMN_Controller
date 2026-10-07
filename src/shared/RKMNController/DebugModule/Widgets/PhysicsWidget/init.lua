--!strict
local PhysicsWidget = {}
PhysicsWidget.__index = PhysicsWidget

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)
local WidgetsFolder = script.Parent
local DataRow = require(WidgetsFolder.DataRow)

type PhysicsResolver = PhysicsResolver.PhysicsResolver
type DataRow = DataRow.DataRow

type PhysicsWidgetData = {
	IsMounted: boolean,
	_physicsResolver: PhysicsResolver,
	_canvas: Frame,
	_velocityXRow: DataRow,
	_velocityYRow: DataRow,
	_facingDirectionRow: DataRow
}

type PhysicsWidgetPrototype = typeof(PhysicsWidget)

export type PhysicsWidget = typeof(setmetatable(
	{} :: PhysicsWidgetData,
	{} :: PhysicsWidgetPrototype
))

function PhysicsWidget.new(physicsResolver: PhysicsResolver): PhysicsWidget
	local data = {
		IsMounted = false,
		_physicsResolver = physicsResolver,
	} :: PhysicsWidgetData

	local self = setmetatable(data, PhysicsWidget)
	self:_createUI()

	return self
end

function PhysicsWidget.MountTo(self: PhysicsWidget, layerCollector: LayerCollector)
	self._canvas.Parent = layerCollector
	self.IsMounted = true
end

function PhysicsWidget.Render(self: PhysicsWidget, physicsResolver: any)
	self._velocityXRow:UpdateValue(physicsResolver.Velocity.X)
	self._velocityYRow:UpdateValue(physicsResolver.Velocity.Y)
	self._facingDirectionRow:UpdateValue(physicsResolver.FacingDirection)
end

function PhysicsWidget:Destroy()
	self._canvas:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

function PhysicsWidget._createDataRows(self: PhysicsWidget): ()
	self._velocityXRow = DataRow.new("Velocity X", "0.00")
    self._velocityXRow:MountTo(self._canvas)
    self._velocityYRow = DataRow.new("Velocity Y", "0.00")
    self._velocityYRow:MountTo(self._canvas)
	self._facingDirectionRow = DataRow.new("Facing Direction", "")
	self._facingDirectionRow:MountTo(self._canvas)
end

function PhysicsWidget._createCanvas(self: PhysicsWidget): ()
    self._canvas = Instance.new("Frame")
    self._canvas.Name = "PhysicsWidget"
    self._canvas.BackgroundTransparency = 1
end

function PhysicsWidget._createListLayout(self: PhysicsWidget): ()
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
    listLayout.VerticalFlex = Enum.UIFlexAlignment.None
    listLayout.Parent = self._canvas
end

function PhysicsWidget._createUI(self: PhysicsWidget): ()
	self:_createCanvas()
	self:_createListLayout()
	self:_createDataRows()
end

table.freeze(PhysicsWidget)

return PhysicsWidget