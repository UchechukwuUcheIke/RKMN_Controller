--!strict

local UITheme = {
    Colors = table.freeze({
        Window = Color3.fromRGB(28, 28, 34),
        Row = Color3.fromRGB(45, 45, 52),
        RowHighlighted = Color3.fromRGB(90, 75, 30),
        AppBar = Color3.fromRGB(36, 36, 44),
        Item = Color3.fromRGB(66, 66, 78),
        ImageBox = Color3.fromRGB(38, 38, 46),

        ButtonNormal = Color3.fromRGB(45, 45, 55),
        ButtonHovered = Color3.fromRGB(62, 62, 76),
        ButtonPressed = Color3.fromRGB(34, 34, 42),
        ButtonDisabled = Color3.fromRGB(36, 36, 42),
        ButtonBorder = Color3.fromRGB(80, 80, 95),
        FocusRing = Color3.fromRGB(90, 160, 255),

        SliderTrack = Color3.fromRGB(60, 60, 72),
        SliderFill = Color3.fromRGB(90, 160, 255),
        SliderKnob = Color3.fromRGB(235, 235, 240),
        SliderDisabled = Color3.fromRGB(85, 85, 97),

        InputBackground = Color3.fromRGB(38, 38, 46),
        PlaceholderText = Color3.fromRGB(140, 140, 150),

        Backdrop = Color3.fromRGB(0, 0, 0),

        Text = Color3.fromRGB(235, 235, 240),
        DisabledText = Color3.fromRGB(115, 115, 125),
        TitleText = Color3.fromRGB(245, 245, 245),
    }),

    Fonts = table.freeze({
        Body = Enum.Font.GothamMedium,
        Title = Enum.Font.GothamBold,
    }),

    TextSizes = table.freeze({
        Body = 18,
        Button = 16,
        Title = 26,
    }),

    ButtonCornerRadius = UDim.new(0, 8),
    RowCornerRadius = UDim.new(0, 8),
    WindowCornerRadius = UDim.new(0, 12),
    ItemCornerRadius = UDim.new(0, 8),
    ImageBoxCornerRadius = UDim.new(0, 6),

    InputPadding = 10,

    ButtonBorderThickness = 1,
    FocusRingThickness = 2,

    SliderTrackHeight = 6,
    SliderKnobSize = 20,
    BackdropTransparency = 0.5,
}

return table.freeze(UITheme)
