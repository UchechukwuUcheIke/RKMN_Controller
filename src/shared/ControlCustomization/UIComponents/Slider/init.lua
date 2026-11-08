--!strict
local Slider = {}
Slider.__index = Slider

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local UITheme = require(script.Parent.UITheme)
local DragTracker = require(script.Parent.DragTracker)

type Signal = typeof(Signal)
type DragTracker = DragTracker.DragTracker

export type SliderProps = {
    Name: string?,
    Min: number,
    Max: number,
    Value: number?,
    Step: number?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    LayoutOrder: number?,
    Enabled: boolean?
}

type SliderData = {
    _root: TextButton,
    _track: Frame,
    _fill: Frame,
    _knob: Frame,
    _min: number,
    _max: number,
    _step: number?,
    _value: number,
    _isEnabled: boolean,
    _dragTracker: DragTracker,
    ValueChanged: Signal,
    DragStarted: Signal,
    DragEnded: Signal
}

export type Slider = typeof(setmetatable({} :: SliderData, Slider))

local DEFAULT_SIZE = UDim2.new(1, 0, 0, 28)

local function addRoundedCorners(parent: GuiObject): ()
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = parent
end

local function createRoot(props: SliderProps): TextButton
    local root = Instance.new("TextButton")
    root.Name = props.Name or "Slider"
    root.Text = ""
    root.AutoButtonColor = false
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Selectable = false
    root.Size = props.Size or DEFAULT_SIZE
    root.Position = props.Position or UDim2.new()
    root.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    root.LayoutOrder = props.LayoutOrder or 0
    return root
end

local function createTrack(): Frame
    local knobInset = UITheme.SliderKnobSize / 2

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.BorderSizePixel = 0
    track.BackgroundColor3 = UITheme.Colors.SliderTrack
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Position = UDim2.new(0, knobInset, 0.5, 0)
    track.Size = UDim2.new(1, -UITheme.SliderKnobSize, 0, UITheme.SliderTrackHeight)
    addRoundedCorners(track)
    return track
end

local function createFill(): Frame
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(0, 1)
    addRoundedCorners(fill)
    return fill
end

local function createKnob(): Frame
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.BorderSizePixel = 0
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(UITheme.SliderKnobSize, UITheme.SliderKnobSize)
    addRoundedCorners(knob)
    return knob
end

function Slider.new(props: SliderProps): Slider
    assert(props.Max > props.Min, "A slider's maximum must be above its minimum")

    local self = setmetatable({}, Slider)

    self._root = createRoot(props)
    self._track = createTrack()
    self._fill = createFill()
    self._knob = createKnob()
    self._min = props.Min
    self._max = props.Max
    self._step = props.Step
    self._value = math.clamp(props.Value or props.Min, props.Min, props.Max)
    self._isEnabled = props.Enabled ~= false
    self._dragTracker = DragTracker.new(self._root)
    self.ValueChanged = Signal.new()
    self.DragStarted = Signal.new()
    self.DragEnded = Signal.new()

    self._fill.Parent = self._track
    self._knob.Parent = self._track
    self._track.Parent = self._root

    self:_subscribeToDrag()
    self:_syncDragTrackerToEnabled()
    self:_renderCurrentState()

    return self :: Slider
end

function Slider.GetGuiObject(self: Slider): GuiObject
    return self._root
end

function Slider.GetValue(self: Slider): number
    return self._value
end

function Slider.SetValue(self: Slider, value: number): ()
    self._value = math.clamp(value, self._min, self._max)
    self:_renderCurrentState()
end

function Slider.Enable(self: Slider): ()
    self._isEnabled = true
    self:_syncDragTrackerToEnabled()
    self:_renderCurrentState()
end

function Slider.Disable(self: Slider): ()
    self._isEnabled = false
    self:_syncDragTrackerToEnabled()
    self:_renderCurrentState()
end

function Slider.IsEnabled(self: Slider): boolean
    return self._isEnabled
end

function Slider.IsDragging(self: Slider): boolean
    return self._dragTracker:IsDragging()
end

function Slider._subscribeToDrag(self: Slider): ()
    self._dragTracker.Began:Connect(function(pointerPosition: Vector2)
        self.DragStarted:Fire()
        self:_setValueFromPointerX(pointerPosition.X)
    end)
    self._dragTracker.Moved:Connect(function(pointerPosition: Vector2)
        self:_setValueFromPointerX(pointerPosition.X)
    end)
    self._dragTracker.Ended:Connect(function()
        self.DragEnded:Fire()
    end)
end

function Slider._syncDragTrackerToEnabled(self: Slider): ()
    if self._isEnabled then
        self._dragTracker:Enable()
    else
        self._dragTracker:Disable()
    end
end

function Slider._setValueFromPointerX(self: Slider, pointerX: number): ()
    local trackWidth = self._track.AbsoluteSize.X
    if trackWidth <= 0 then
        return
    end

    self:_setValueFromFraction((pointerX - self._track.AbsolutePosition.X) / trackWidth)
end

function Slider._setValueFromFraction(self: Slider, fraction: number): ()
    local newValue = self:_valueFromFraction(fraction)
    if newValue == self._value then
        return
    end

    self._value = newValue
    self:_renderCurrentState()
    self.ValueChanged:Fire(newValue)
end

function Slider._valueFromFraction(self: Slider, fraction: number): number
    local value = self._min + math.clamp(fraction, 0, 1) * (self._max - self._min)

    local step = self._step
    if step then
        value = self._min + math.round((value - self._min) / step) * step
    end

    return math.clamp(value, self._min, self._max)
end

function Slider._fractionFromValue(self: Slider): number
    return (self._value - self._min) / (self._max - self._min)
end

function Slider._renderCurrentState(self: Slider): ()
    local fraction = self:_fractionFromValue()
    self._fill.Size = UDim2.fromScale(fraction, 1)
    self._knob.Position = UDim2.fromScale(fraction, 0.5)

    self._fill.BackgroundColor3 = if self._isEnabled then UITheme.Colors.SliderFill else UITheme.Colors.SliderDisabled
    self._knob.BackgroundColor3 = if self._isEnabled then UITheme.Colors.SliderKnob else UITheme.Colors.SliderDisabled
end

function Slider.Destroy(self: Slider): ()
    self._dragTracker:Destroy()
    self.ValueChanged:DisconnectAll()
    self.DragStarted:DisconnectAll()
    self.DragEnded:DisconnectAll()
    self._root:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(Slider)
return Slider
