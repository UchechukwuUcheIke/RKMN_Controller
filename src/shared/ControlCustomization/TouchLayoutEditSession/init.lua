--!strict
local TouchLayoutEditSession = {}
TouchLayoutEditSession.__index = TouchLayoutEditSession

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.DevPackages.goodsignal)
local TouchGamepadFolder = ReplicatedStorage.TouchGamepad
local TouchGamepadLayoutRegistry = require(TouchGamepadFolder.TouchGamepadLayoutRegistry)
local ButtonTransformRules = require(TouchGamepadFolder.ButtonTransformRules)
local ButtonTransformModule = require(TouchGamepadFolder.ButtonTransform)

type Signal = typeof(Signal)
type ControlID = TouchGamepadLayoutRegistry.ControlID
type ButtonTransformChanges = ButtonTransformModule.ButtonTransformChanges
type TouchGamepadLayout = TouchGamepadLayoutRegistry.TouchGamepadLayout

type TouchLayoutEditSessionData = {
    _savedLayout: TouchGamepadLayout,
    _draftLayout: TouchGamepadLayout,
    _undoStack: {TouchGamepadLayout},
    _redoStack: {TouchGamepadLayout},
    _gestureStartLayout: TouchGamepadLayout?,
    _selectedControl: ControlID?,
    Changed: Signal
}

export type TouchLayoutEditSession = typeof(setmetatable({} :: TouchLayoutEditSessionData, TouchLayoutEditSession))

function TouchLayoutEditSession.new(layout: TouchGamepadLayout): TouchLayoutEditSession
    local self = setmetatable({}, TouchLayoutEditSession)

    self._savedLayout = layout
    self._draftLayout = layout
    self._undoStack = {}
    self._redoStack = {}
    self._gestureStartLayout = nil
    self._selectedControl = nil
    self.Changed = Signal.new()

    return self :: TouchLayoutEditSession
end

function TouchLayoutEditSession.GetLayout(self: TouchLayoutEditSession): TouchGamepadLayout
    return self._draftLayout
end

function TouchLayoutEditSession.GetSelectedControl(self: TouchLayoutEditSession): ControlID?
    return self._selectedControl
end

function TouchLayoutEditSession.SelectControl(self: TouchLayoutEditSession, controlID: ControlID?): ()
    if controlID and not self._draftLayout:HasControl(controlID) then
        error(`Layout has no control {controlID}`)
    end
    if controlID == self._selectedControl then
        return
    end

    self._selectedControl = controlID
    self.Changed:Fire()
end

function TouchLayoutEditSession.SetControlPosition(self: TouchLayoutEditSession, controlID: ControlID, position: UDim2): ()
    self:_editControlTransform(controlID, { Position = position })
end

function TouchLayoutEditSession.SetControlScale(self: TouchLayoutEditSession, controlID: ControlID, scale: number): ()
    self:_editControlTransform(controlID, { Scale = ButtonTransformRules.ClampScale(scale) })
end

function TouchLayoutEditSession.SetControlTransparency(self: TouchLayoutEditSession, controlID: ControlID, transparency: number): ()
    self:_editControlTransform(controlID, { Transparency = ButtonTransformRules.ClampTransparency(transparency) })
end

function TouchLayoutEditSession.BeginGesture(self: TouchLayoutEditSession): ()
    if self:_isGestureInProgress() then
        error("A gesture is already in progress")
    end
    self._gestureStartLayout = self._draftLayout
end

function TouchLayoutEditSession.EndGesture(self: TouchLayoutEditSession): ()
    local startLayout = self._gestureStartLayout
    if not startLayout then
        return
    end
    self._gestureStartLayout = nil

    if not startLayout:Equals(self._draftLayout) then
        self:_recordUndoStep(startLayout)
        self.Changed:Fire()
    end
end

function TouchLayoutEditSession.CanUndo(self: TouchLayoutEditSession): boolean
    local isUndoStackEmpty = #self._undoStack == 0
    
    return not isUndoStackEmpty and not self:_isGestureInProgress()
end

function TouchLayoutEditSession._isGestureInProgress(self: TouchLayoutEditSession): boolean
    local hasBegunGesture = self._gestureStartLayout ~= nil
    return hasBegunGesture
end

function TouchLayoutEditSession.CanRedo(self: TouchLayoutEditSession): boolean
    local isRedoStackEmpty = #self._redoStack == 0
    return not isRedoStackEmpty and not self:_isGestureInProgress()
end

function TouchLayoutEditSession.Undo(self: TouchLayoutEditSession): ()
    if not self:CanUndo() then
        return
    end

    table.insert(self._redoStack, self._draftLayout)
    self._draftLayout = table.remove(self._undoStack) :: TouchGamepadLayout
    self.Changed:Fire()
end

function TouchLayoutEditSession.Redo(self: TouchLayoutEditSession): ()
    if not self:CanRedo() then
        return
    end

    table.insert(self._undoStack, self._draftLayout)
    self._draftLayout = table.remove(self._redoStack) :: TouchGamepadLayout
    self.Changed:Fire()
end

function TouchLayoutEditSession.IsDirty(self: TouchLayoutEditSession): boolean
    return not self._draftLayout:Equals(self._savedLayout)
end

function TouchLayoutEditSession.DiscardChanges(self: TouchLayoutEditSession): ()
    if not self:IsDirty() or self:_isGestureInProgress() then
        return
    end

    self:_recordUndoStep(self._draftLayout)
    self._draftLayout = self._savedLayout
    self.Changed:Fire()
end

function TouchLayoutEditSession.MarkSaved(self: TouchLayoutEditSession): ()
    self._savedLayout = self._draftLayout
    self.Changed:Fire()
end

function TouchLayoutEditSession._editControlTransform(self: TouchLayoutEditSession, controlID: ControlID, changes: ButtonTransformChanges): ()
    local current = self._draftLayout:GetTransform(controlID)
    if not current then
        error(`Layout has no control {controlID}`)
    end

    local edited = current:CopyWithChanges(changes)
    if current:Equals(edited) then
        return
    end

    local previousLayout = self._draftLayout
    self._draftLayout = previousLayout:CopyWithTransform(controlID, edited)

    -- Inside a gesture the single undo step is recorded when it ends.
    if not self:_isGestureInProgress() then
        self:_recordUndoStep(previousLayout)
    end
    self.Changed:Fire()
end

function TouchLayoutEditSession._recordUndoStep(self: TouchLayoutEditSession, layoutBeforeStep: TouchGamepadLayout): ()
    table.insert(self._undoStack, layoutBeforeStep)
    table.clear(self._redoStack)
end

function TouchLayoutEditSession.Destroy(self: TouchLayoutEditSession): ()
    self.Changed:DisconnectAll()
    setmetatable(self :: any, nil)
    table.freeze(self)
end

table.freeze(TouchLayoutEditSession)
return TouchLayoutEditSession
