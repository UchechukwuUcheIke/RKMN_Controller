--!strict
local FallbackImage = {}
FallbackImage.__index = FallbackImage

local UITheme = require(script.Parent.UITheme)
local Panel = require(script.Parent.Panel)
local PanelTone = require(script.Parent.PanelTone)

type Panel = Panel.Panel

export type FallbackImageProps = {
    Name: string?,
    ImageId: string?,
    FallbackText: string?,
    Size: UDim2?,
    Position: UDim2?,
    LayoutOrder: number?
}

type FallbackImageData = {
    _panel: Panel,
    _imageLabel: ImageLabel,
    _fallbackLabel: TextLabel,
    _loadedConnection: RBXScriptConnection
}

export type FallbackImage = typeof(setmetatable({} :: FallbackImageData, FallbackImage))

local DEFAULT_SIZE = UDim2.fromOffset(24, 24)

local function createPanel(props: FallbackImageProps): Panel
    local panelProps: Panel.PanelProps = {
        Name = props.Name or "FallbackImage",
        Tone = PanelTone.ImageBox,
        Size = props.Size or DEFAULT_SIZE,
        Position = props.Position,
        LayoutOrder = props.LayoutOrder,
    }
    return Panel.new(panelProps)
end

local function createImageLabel(imageId: string?): ImageLabel
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "Image"
    imageLabel.BackgroundTransparency = 1
    imageLabel.BorderSizePixel = 0
    imageLabel.Size = UDim2.fromScale(1, 1)
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.Image = imageId or ""
    return imageLabel
end

local function createFallbackLabel(text: string?): TextLabel
    local fallbackLabel = Instance.new("TextLabel")
    fallbackLabel.Name = "Fallback"
    fallbackLabel.BackgroundTransparency = 1
    fallbackLabel.BorderSizePixel = 0
    fallbackLabel.Size = UDim2.fromScale(1, 1)
    fallbackLabel.TextScaled = true
    fallbackLabel.Font = UITheme.Fonts.Body
    fallbackLabel.TextColor3 = UITheme.Colors.Text
    fallbackLabel.Text = text or ""
    return fallbackLabel
end

function FallbackImage.new(props: FallbackImageProps): FallbackImage
    local self = setmetatable({}, FallbackImage)

    self._panel = createPanel(props)
    self._imageLabel = createImageLabel(props.ImageId)
    self._fallbackLabel = createFallbackLabel(props.FallbackText)

    local panelObject = self._panel:GetGuiObject()
    self._imageLabel.Parent = panelObject
    self._fallbackLabel.Parent = panelObject

    self._loadedConnection = self._imageLabel:GetPropertyChangedSignal("IsLoaded"):Connect(function()
        self:_renderCurrentState()
    end)
    self:_renderCurrentState()

    return self :: FallbackImage
end

function FallbackImage.GetGuiObject(self: FallbackImage): GuiObject
    return self._panel:GetGuiObject()
end

function FallbackImage.SetImageId(self: FallbackImage, imageId: string?): ()
    self._imageLabel.Image = imageId or ""
    self:_renderCurrentState()
end

function FallbackImage.SetFallbackText(self: FallbackImage, text: string): ()
    self._fallbackLabel.Text = text
end

function FallbackImage._shouldShowImage(self: FallbackImage): boolean
    return self._imageLabel.Image ~= "" and self._imageLabel.IsLoaded
end

function FallbackImage._renderCurrentState(self: FallbackImage): ()
    local showImage = self:_shouldShowImage()
    self._imageLabel.Visible = showImage
    self._fallbackLabel.Visible = not showImage
end

function FallbackImage.Destroy(self: FallbackImage): ()
    self._loadedConnection:Disconnect()
    self._panel:Destroy()

    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(FallbackImage)
return FallbackImage
