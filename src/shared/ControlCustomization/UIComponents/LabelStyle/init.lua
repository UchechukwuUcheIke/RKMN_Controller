--!strict
export type LabelStyle = "Body" | "Title"

local LabelStyle = {
    Body = "Body" :: LabelStyle,
    Title = "Title" :: LabelStyle,
}

table.freeze(LabelStyle)

return LabelStyle
