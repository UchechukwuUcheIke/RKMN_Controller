--!strict
local DPad = {}
DPad.__index = DPad

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputAction = require(ReplicatedStorage.PlayerInput.InputAction)
local TouchGamepadLayoutRegistry = require(script.Parent.Parent.TouchGamepadLayoutRegistry)
local ButtonTransformRules = require(script.Parent.Parent.ButtonTransformRules)
local ButtonTransformModule = require(script.Parent.Parent.ButtonTransform)
local ActionButtonModule = require(script.Parent.ActionButton)

type ActionButton = ActionButtonModule.ActionButton
type ButtonTransform = TouchGamepadLayoutRegistry.ButtonTransform

type DPadData = {
    _frame: Frame,
    _leftButton: ActionButton,
    _rightButton: ActionButton
}

export type DPad = typeof(setmetatable({} :: DPadData, DPad))

local ARROW_WIDTH_SCALE = 0.45

local function makeArrowTransform(isLeft: boolean, transparency: number): ButtonTransform
    local edge = if isLeft then 0 else 1
    return ButtonTransformModule.new({
        Position = UDim2.fromScale(edge, 0.5),
        BaseSize = UDim2.fromScale(ARROW_WIDTH_SCALE, 1),
        AnchorPoint = Vector2.new(edge, 0.5),
        Scale = 1,
        Transparency = transparency
    })
end

function DPad.new(parent: Instance?): DPad
    local self = setmetatable({}, DPad)

    local frame = Instance.new("Frame")
    frame.Name = "DPad"
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    self._frame = frame
    self._leftButton = ActionButtonModule.new(InputAction.Left, "<", frame, "Rounded")
    self._rightButton = ActionButtonModule.new(InputAction.Right, ">", frame, "Rounded")

    return self :: DPad
end

function DPad.GetLeftButton(self: DPad): ActionButton
    return self._leftButton
end

function DPad.GetRightButton(self: DPad): ActionButton
    return self._rightButton
end

function DPad.SetTransform(self: DPad, transform: ButtonTransform): ()
    self._frame.Position = transform.Position
    self._frame.Size = ButtonTransformRules.GetEffectiveSize(transform)
    self._frame.AnchorPoint = transform.AnchorPoint

    self._leftButton:SetTransform(makeArrowTransform(true, transform.Transparency))
    self._rightButton:SetTransform(makeArrowTransform(false, transform.Transparency))
end

function DPad.ResetVisual(self: DPad): ()
    self._leftButton:ResetVisual()
    self._rightButton:ResetVisual()
end

function DPad.Destroy(self: DPad): ()
    self._leftButton:Destroy()
    self._rightButton:Destroy()
    self._frame:Destroy()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(DPad)
return DPad
