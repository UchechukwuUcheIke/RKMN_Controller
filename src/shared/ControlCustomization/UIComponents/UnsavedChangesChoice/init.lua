--!strict
export type UnsavedChangesChoice = "Save" | "Discard" | "Cancel"

local UnsavedChangesChoice = {
    Save = "Save" :: UnsavedChangesChoice,
    Discard = "Discard" :: UnsavedChangesChoice,
    Cancel = "Cancel" :: UnsavedChangesChoice,
}

table.freeze(UnsavedChangesChoice)

return UnsavedChangesChoice
