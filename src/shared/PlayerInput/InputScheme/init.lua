--!strict
local InputAction = require(script.Parent.InputAction)

export type InputBinding = Enum.KeyCode | Enum.UserInputType
export type Bindings = {[InputBinding]: boolean}
export type InputScheme = {[InputAction.ActionID]: Bindings}

return nil
