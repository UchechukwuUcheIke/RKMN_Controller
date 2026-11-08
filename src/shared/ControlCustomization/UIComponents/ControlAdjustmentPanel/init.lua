--!strict
local ControlAdjustmentPanel = {}
ControlAdjustmentPanel.__index = ControlAdjustmentPanel

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local ButtonTransformRules = require(ReplicatedStorage.TouchGamepad.ButtonTransformRules)
local UIComponents = script.Parent
local Label = require(UIComponents.Label)
local Panel = require(UIComponents.Panel)
local PanelTone = require(UIComponents.PanelTone)
local Slider = require(UIComponents.Slider)

type Signal = typeof(Signal)
type Label = Label.Label
type Panel = Panel.Panel
type Slider = Slider.Slider

export type ControlAdjustmentPanelProps = {
    Name: string?,
    Position: UDim2?,
    AnchorPoint: Vector2?
}

type ControlAdjustmentPanelData = {
    _panel: Panel,
    _titleLabel: Label,
    _sizeLabel: Label,
    _sizeSlider: Slider,
    _opacityLabel: Label,
    _opacitySlider: Slider,
    _activeAdjustments: number,
    ScaleChanged: Signal,
    TransparencyChanged: Signal,
    AdjustmentStarted: Signal,
    AdjustmentEnded: Signal
}

export type ControlAdjustmentPanel = typeof(setmetatable({} :: ControlAdjustmentPanelData, ControlAdjustmentPanel))

local PANEL_SIZE = UDim2.fromOffset(300, 152)
local PADDING = 12
local TITLE_TOP = 8
local SIZE_LABEL_TOP = 38
local SIZE_SLIDER_TOP = 58
local OPACITY_LABEL_TOP = 90
local OPACITY_SLIDER_TOP = 110
local LABEL_HEIGHT = 20
local SLIDER_HEIGHT = 28
local SLIDER_STEP = 0.05
local NOTHING_SELECTED_TEXT = "Select a control"

local function formatPercent(name: string, fraction: number): string
    return `{name} {math.round(fraction * 100)}%`
end

local function createPanel(props: ControlAdjustmentPanelProps): Panel
    local panelProps: Panel.PanelProps = {
        Name = props.Name or "ControlAdjustmentPanel",
        Tone = PanelTone.Window,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        Size = PANEL_SIZE,
    }
    return Panel.new(panelProps)
end

local function createRowLabel(name: string, text: string, top: number): Label
    local labelProps: Label.LabelProps = {
        Name = name,
        Text = text,
        Position = UDim2.fromOffset(PADDING, top),
        Size = UDim2.new(1, -PADDING * 2, 0, LABEL_HEIGHT),
    }
    return Label.new(labelProps)
end

local function createRowSlider(name: string, top: number, min: number, max: number): Slider
    local sliderProps: Slider.SliderProps = {
        Name = name,
        Min = min,
        Max = max,
        Step = SLIDER_STEP,
        Position = UDim2.fromOffset(PADDING, top),
        Size = UDim2.new(1, -PADDING * 2, 0, SLIDER_HEIGHT),
        Enabled = false,
    }
    return Slider.new(sliderProps)
end

function ControlAdjustmentPanel.new(props: ControlAdjustmentPanelProps): ControlAdjustmentPanel
    local self = setmetatable({}, ControlAdjustmentPanel)

    self._panel = createPanel(props)
    self._titleLabel = createRowLabel("Title", NOTHING_SELECTED_TEXT, TITLE_TOP)
    self._sizeLabel = createRowLabel("SizeLabel", "Size", SIZE_LABEL_TOP)
    self._sizeSlider = createRowSlider("SizeSlider", SIZE_SLIDER_TOP, ButtonTransformRules.MIN_SCALE, ButtonTransformRules.MAX_SCALE)
    self._opacityLabel = createRowLabel("OpacityLabel", "Opacity", OPACITY_LABEL_TOP)
    self._opacitySlider = createRowSlider("OpacitySlider", OPACITY_SLIDER_TOP, ButtonTransformRules.MIN_OPACITY, ButtonTransformRules.MAX_OPACITY)
    self._activeAdjustments = 0
    self.ScaleChanged = Signal.new()
    self.TransparencyChanged = Signal.new()
    self.AdjustmentStarted = Signal.new()
    self.AdjustmentEnded = Signal.new()

    self:_parentChildrenToPanel()
    self:_forwardSliderEvents()

    return self :: ControlAdjustmentPanel
end

function ControlAdjustmentPanel.GetGuiObject(self: ControlAdjustmentPanel): GuiObject
    return self._panel:GetGuiObject()
end

-- Shows a control's current values without announcing them, so showing a selection is never mistaken for an edit.
function ControlAdjustmentPanel.ShowControl(self: ControlAdjustmentPanel, controlName: string, scale: number, transparency: number): ()
    local opacity = ButtonTransformRules.TransparencyToOpacity(transparency)

    self._titleLabel:SetText(controlName)
    self._sizeLabel:SetText(formatPercent("Size", scale))
    self._opacityLabel:SetText(formatPercent("Opacity", opacity))
    self._sizeSlider:SetValue(scale)
    self._opacitySlider:SetValue(opacity)
    self._sizeSlider:Enable()
    self._opacitySlider:Enable()
end

function ControlAdjustmentPanel.ShowNothingSelected(self: ControlAdjustmentPanel): ()
    self._titleLabel:SetText(NOTHING_SELECTED_TEXT)
    self._sizeLabel:SetText("Size")
    self._opacityLabel:SetText("Opacity")
    self._sizeSlider:Disable()
    self._opacitySlider:Disable()
end

function ControlAdjustmentPanel.SetVisible(self: ControlAdjustmentPanel, isVisible: boolean): ()
    self._panel:SetVisible(isVisible)
end

function ControlAdjustmentPanel._parentChildrenToPanel(self: ControlAdjustmentPanel): ()
    local panelObject = self._panel:GetGuiObject()
    self._titleLabel:GetGuiObject().Parent = panelObject
    self._sizeLabel:GetGuiObject().Parent = panelObject
    self._sizeSlider:GetGuiObject().Parent = panelObject
    self._opacityLabel:GetGuiObject().Parent = panelObject
    self._opacitySlider:GetGuiObject().Parent = panelObject
end

function ControlAdjustmentPanel._forwardSliderEvents(self: ControlAdjustmentPanel): ()
    self._sizeSlider.ValueChanged:Connect(function(scale: number)
        self._sizeLabel:SetText(formatPercent("Size", scale))
        self.ScaleChanged:Fire(scale)
    end)
    self._opacitySlider.ValueChanged:Connect(function(opacity: number)
        self._opacityLabel:SetText(formatPercent("Opacity", opacity))
        self.TransparencyChanged:Fire(ButtonTransformRules.OpacityToTransparency(opacity))
    end)

    for _, slider in ipairs({ self._sizeSlider, self._opacitySlider }) do
        slider.DragStarted:Connect(function()
            self:_handleAdjustmentStarted()
        end)
        slider.DragEnded:Connect(function()
            self:_handleAdjustmentEnded()
        end)
    end
end

-- Two fingers can pull both sliders at once; the edit session only has room for one gesture at a time.
function ControlAdjustmentPanel._handleAdjustmentStarted(self: ControlAdjustmentPanel): ()
    self._activeAdjustments += 1
    if self._activeAdjustments == 1 then
        self.AdjustmentStarted:Fire()
    end
end

function ControlAdjustmentPanel._handleAdjustmentEnded(self: ControlAdjustmentPanel): ()
    self._activeAdjustments -= 1
    if self._activeAdjustments == 0 then
        self.AdjustmentEnded:Fire()
    end
end

function ControlAdjustmentPanel.Destroy(self: ControlAdjustmentPanel): ()
    self.ScaleChanged:DisconnectAll()
    self.TransparencyChanged:DisconnectAll()
    self.AdjustmentStarted:DisconnectAll()
    self.AdjustmentEnded:DisconnectAll()
    self._opacitySlider:Destroy()
    self._opacityLabel:Destroy()
    self._sizeSlider:Destroy()
    self._sizeLabel:Destroy()
    self._titleLabel:Destroy()
    self._panel:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(ControlAdjustmentPanel)
return ControlAdjustmentPanel
