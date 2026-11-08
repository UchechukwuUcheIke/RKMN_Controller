--!strict
local TouchLayoutCanvas = {}
TouchLayoutCanvas.__index = TouchLayoutCanvas

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local TouchGamepadFolder = ReplicatedStorage.TouchGamepad
local TouchGamepadLayoutRegistry = require(TouchGamepadFolder.TouchGamepadLayoutRegistry)
local ButtonTransformRules = require(TouchGamepadFolder.ButtonTransformRules)
local MobileButtonPositioner = require(TouchGamepadFolder.MobileButtonPositioner)
local TouchGamepadUI = require(TouchGamepadFolder.UserInterface.TouchGamepadUI)
local DragTracker = require(script.Parent.DragTracker)
local UITheme = require(script.Parent.UITheme)

type Signal = typeof(Signal)
type ControlID = TouchGamepadLayoutRegistry.ControlID
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout
type MobileButtonPositioner = MobileButtonPositioner.MobileButtonPositioner
type TouchGamepadUI = TouchGamepadUI.TouchGamepadUI
type DragTracker = DragTracker.DragTracker

-- The gamepad UI here is never given to the player's input, so its buttons are only for looking at and dragging.
export type TouchLayoutCanvasProps = {
    GamepadUI: TouchGamepadUI,
    Positioner: MobileButtonPositioner,
    GetViewportSize: () -> Vector2,
    FixedControls: {ControlID}
}

type ControlHandle = {
    Button: TextButton,
    Outline: UIStroke,
    Tracker: DragTracker
}

type ActiveDrag = {
    ControlID: ControlID,
    StartPointer: Vector2,
    StartPosition: Vector2
}

type TouchLayoutCanvasData = {
    _gamepadUI: TouchGamepadUI,
    _positioner: MobileButtonPositioner,
    _getViewportSize: () -> Vector2,
    _fixedControls: {[ControlID]: boolean},
    _handles: {[ControlID]: ControlHandle},
    _layout: TouchGamepadLayout?,
    _pressedControl: ControlID?,
    _activeDrag: ActiveDrag?,
    ControlPressed: Signal,
    ControlDragged: Signal,
    PointerReleased: Signal
}

export type TouchLayoutCanvas = typeof(setmetatable({} :: TouchLayoutCanvasData, TouchLayoutCanvas))

local HANDLE_Z_INDEX = 10

local function toSet(controlIDs: {ControlID}): {[ControlID]: boolean}
    local set: {[ControlID]: boolean} = {}
    for _, controlID in ipairs(controlIDs) do
        set[controlID] = true
    end
    return set
end

local function hasArea(viewportSize: Vector2): boolean
    return viewportSize.X > 0 and viewportSize.Y > 0
end

-- A position saved with offsets is read as the screen fraction it works out to.
local function positionToScale(position: UDim2, viewportSize: Vector2): Vector2
    if not hasArea(viewportSize) then
        return Vector2.new(position.X.Scale, position.Y.Scale)
    end
    return Vector2.new(
        position.X.Scale + position.X.Offset / viewportSize.X,
        position.Y.Scale + position.Y.Offset / viewportSize.Y
    )
end

local function matchCorners(handleButton: TextButton, controlInstance: GuiObject): ()
    local controlCorner = controlInstance:FindFirstChildOfClass("UICorner")
    if not controlCorner then
        return
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = controlCorner.CornerRadius
    corner.Parent = handleButton
end

-- Fills its control and sits above everything inside it, so the D-Pad's own arrows never get the press.
local function createHandleButton(controlInstance: GuiObject): TextButton
    local button = Instance.new("TextButton")
    button.Name = "Handle"
    button.Text = ""
    button.AutoButtonColor = false
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.Selectable = false
    button.Size = UDim2.fromScale(1, 1)
    button.ZIndex = HANDLE_Z_INDEX
    matchCorners(button, controlInstance)
    return button
end

local function createOutline(parent: GuiObject): UIStroke
    local outline = Instance.new("UIStroke")
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Color = UITheme.Colors.FocusRing
    outline.Thickness = UITheme.FocusRingThickness
    outline.Enabled = false
    outline.Parent = parent
    return outline
end

function TouchLayoutCanvas.new(props: TouchLayoutCanvasProps): TouchLayoutCanvas
    local self = setmetatable({}, TouchLayoutCanvas)

    self._gamepadUI = props.GamepadUI
    self._positioner = props.Positioner
    self._getViewportSize = props.GetViewportSize
    self._fixedControls = toSet(props.FixedControls)
    self._handles = {}
    self._layout = nil
    self._pressedControl = nil
    self._activeDrag = nil
    self.ControlPressed = Signal.new()
    self.ControlDragged = Signal.new()
    self.PointerReleased = Signal.new()

    for controlID, control in pairs(props.GamepadUI:GetPositionableControls()) do
        props.Positioner:RegisterControl(controlID, control)
        self._handles[controlID] = self:_createHandle(controlID, control:GetInstance())
    end

    return self :: TouchLayoutCanvas
end

function TouchLayoutCanvas.Render(self: TouchLayoutCanvas, layout: TouchGamepadLayout): ()
    self._layout = layout
    self._positioner:ApplyLayout(layout)
end

function TouchLayoutCanvas.SetSelected(self: TouchLayoutCanvas, controlID: ControlID?): ()
    for handleID, handle in pairs(self._handles) do
        handle.Outline.Enabled = handleID == controlID
    end
end

function TouchLayoutCanvas.SetVisible(self: TouchLayoutCanvas, isVisible: boolean): ()
    self._gamepadUI:SetVisible(isVisible)
end

function TouchLayoutCanvas.SetDisplayOrder(self: TouchLayoutCanvas, displayOrder: number): ()
    self._gamepadUI:SetDisplayOrder(displayOrder)
end

function TouchLayoutCanvas._createHandle(self: TouchLayoutCanvas, controlID: ControlID, controlInstance: GuiObject): ControlHandle
    local button = createHandleButton(controlInstance)
    button.Parent = controlInstance

    local tracker = DragTracker.new(button)
    tracker.Began:Connect(function(pointerPosition: Vector2)
        self:_handlePointerBegan(controlID, pointerPosition)
    end)
    tracker.Moved:Connect(function(pointerPosition: Vector2)
        self:_handlePointerMoved(controlID, pointerPosition)
    end)
    tracker.Ended:Connect(function()
        self:_handlePointerEnded(controlID)
    end)

    return { Button = button, Outline = createOutline(button), Tracker = tracker }
end

-- One control at a time: a second finger landing on another control is ignored until the first lets go.
function TouchLayoutCanvas._handlePointerBegan(self: TouchLayoutCanvas, controlID: ControlID, pointerPosition: Vector2): ()
    if self._pressedControl then
        return
    end

    self._pressedControl = controlID
    self._activeDrag = self:_startDragIfMovable(controlID, pointerPosition)
    self.ControlPressed:Fire(controlID)
end

function TouchLayoutCanvas._startDragIfMovable(self: TouchLayoutCanvas, controlID: ControlID, pointerPosition: Vector2): ActiveDrag?
    local layout = self._layout
    local transform = if layout then layout:GetTransform(controlID) else nil
    if self._fixedControls[controlID] or not transform then
        return nil
    end

    return {
        ControlID = controlID,
        StartPointer = pointerPosition,
        StartPosition = positionToScale(transform.Position, self._getViewportSize()),
    }
end

function TouchLayoutCanvas._handlePointerMoved(self: TouchLayoutCanvas, controlID: ControlID, pointerPosition: Vector2): ()
    local drag = self._activeDrag
    local layout = self._layout
    local viewportSize = self._getViewportSize()
    if controlID ~= self._pressedControl or not drag or not layout or not hasArea(viewportSize) then
        return
    end

    local transform = layout:GetTransform(drag.ControlID)
    if not transform then
        return
    end

    local pointerShift = pointerPosition - drag.StartPointer
    local wantedPosition = drag.StartPosition + Vector2.new(pointerShift.X / viewportSize.X, pointerShift.Y / viewportSize.Y)
    local sizePixels = ButtonTransformRules.GetEffectivePixelSize(transform, viewportSize)
    local keptOnScreen = ButtonTransformRules.ClampPosition(wantedPosition, sizePixels, transform.AnchorPoint, viewportSize)

    self.ControlDragged:Fire(drag.ControlID, UDim2.fromScale(keptOnScreen.X, keptOnScreen.Y))
end

function TouchLayoutCanvas._handlePointerEnded(self: TouchLayoutCanvas, controlID: ControlID): ()
    if controlID ~= self._pressedControl then
        return
    end

    self._pressedControl = nil
    self._activeDrag = nil
    self.PointerReleased:Fire()
end

function TouchLayoutCanvas.Destroy(self: TouchLayoutCanvas): ()
    for _, handle in pairs(self._handles) do
        handle.Tracker:Destroy()
        handle.Button:Destroy()
    end
    table.clear(self._handles)
    self.ControlPressed:DisconnectAll()
    self.ControlDragged:DisconnectAll()
    self.PointerReleased:DisconnectAll()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchLayoutCanvas)
return TouchLayoutCanvas
