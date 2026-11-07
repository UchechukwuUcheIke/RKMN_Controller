--!strict
export type PanelTone = "Window" | "Row" | "RowHighlighted" | "AppBar" | "Item" | "ImageBox"

local PanelTone = {
    Window = "Window" :: PanelTone,
    Row = "Row" :: PanelTone,
    RowHighlighted = "RowHighlighted" :: PanelTone,
    AppBar = "AppBar" :: PanelTone,
    Item = "Item" :: PanelTone,
    ImageBox = "ImageBox" :: PanelTone,
}

table.freeze(PanelTone)

return PanelTone
