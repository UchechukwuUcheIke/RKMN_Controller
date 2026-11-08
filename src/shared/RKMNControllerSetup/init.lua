local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DebugModuleFolder = ReplicatedStorage.DebugModule
local DebugFacade = require(DebugModuleFolder.DebugFacade)
local RKMNController = require(RKMNControllerFolder.RKMNController)
local KinematicWorld = require(ReplicatedStorage.KinematicWorld)
local RunServiceAdapter = require(ReplicatedStorage.RunServiceAdapter)
local RenderPriorities = require(ReplicatedStorage.RenderPriorities)
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local MovementStats = require(RKMNControllerFolder.MovementStats)
local TimerUtility = require(RKMNControllerFolder.TimerUtility)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputMapper = require(PlayerInputFolder.InputMapper)
local ControlProfile = require(PlayerInputFolder.ControlProfile)
local KeyboardSchemes = require(PlayerInputFolder.KeyboardSchemes)
local GamepadSchemes = require(PlayerInputFolder.GamepadSchemes)
local DeviceDetector = require(PlayerInputFolder.DeviceDetector)
local PlayerInputFacade = require(PlayerInputFolder.PlayerInputFacade)
local BindingCapture = require(PlayerInputFolder.BindingCapture)
local ControlCustomizationFolder = ReplicatedStorage.ControlCustomization
local ControlCustomizationUI = require(ControlCustomizationFolder.ControlCustomizationUI)
local ControlCustomizationView = require(ControlCustomizationFolder.ControlCustomizationView)
local TouchLayoutEditor = require(ControlCustomizationFolder.TouchLayoutEditor)
local TouchLayoutCanvas = require(ControlCustomizationFolder.UIComponents.TouchLayoutCanvas)
local TouchLayoutScreen = require(ControlCustomizationFolder.UIComponents.TouchLayoutScreen)
local TouchGamepadFolder = ReplicatedStorage.TouchGamepad
local TouchGamepadPresenter = require(TouchGamepadFolder.TouchGamepadPresenter)
local TouchGamepadUI = require(TouchGamepadFolder.UserInterface.TouchGamepadUI)
local MobileButtonPositioner = require(TouchGamepadFolder.MobileButtonPositioner)
local TouchGamepadLayoutRegistry = require(TouchGamepadFolder.TouchGamepadLayoutRegistry)
local TouchLayoutPresets = require(TouchGamepadFolder.TouchLayoutPresets)
local TouchLayoutProfile = require(TouchGamepadFolder.TouchLayoutProfile)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)
local StateMachineContext = require(RKMNControllerFolder.FSMContext)
local DiagnosticControllerQuery = require(DebugModuleFolder.DiagnosticCollisionQuery)

type CollisionConstants = CollisionConstants.CollisionConstants
type TimerUtility = TimerUtility.TimerUtility
type CollisionQuery = CollisionQuery.CollisionQuery
type InputMapper = InputMapper.InputMapper
type DeviceDetector = DeviceDetector.DeviceDetector
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
type TouchGamepadPresenter = TouchGamepadPresenter.TouchGamepadPresenter
type ControlCustomizationUI = ControlCustomizationUI.ControlCustomizationUI
type ControlID = TouchGamepadLayoutRegistry.ControlID
type TouchLayoutEditor = TouchLayoutEditor.TouchLayoutEditor
type TouchLayoutCanvas = TouchLayoutCanvas.TouchLayoutCanvas
type TouchLayoutScreen = TouchLayoutScreen.TouchLayoutScreen
type TouchGamepadUI = TouchGamepadUI.TouchGamepadUI
type MobileButtonPositioner = MobileButtonPositioner.MobileButtonPositioner
type MovementStateMachine = MovementStateMachine.MovementStateMachine
type PhysicsResolver = PhysicsResolver.PhysicsResolver
type RKMNController = RKMNController.RKMNController
type RKMNControllerDependencies = RKMNController.RKMNControllerDependencies
type StateMachineContext = StateMachineContext.FSMContext
type StateMachineContextDependencies = StateMachineContext.FSMContextDependencies
type DiagnosticControllerQuery = DiagnosticControllerQuery.DiagnosticCollisionQuery

local RKMNControllerSetup = {}

local kinematicWorld = KinematicWorld.new()
local runServiceAdapter = RunServiceAdapter.new("LiveKinematicLoop", RenderPriorities.World, function(dt: number)
    kinematicWorld:StepWorld(dt)
end)

local function mountScreenGui(): ScreenGui
    local PlayerGui = LocalPlayer.PlayerGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = PlayerGui
    return screenGui
end

local function makeDependencies(character: Model, constants: CollisionConstants, collisionQuery: CollisionQuery, inputMapper: InputMapper): RKMNControllerDependencies
    local movementStats = MovementStats.new()
    local timerUtility = TimerUtility.new()
    local playerInput = PlayerInputFacade.new(timerUtility, inputMapper)
    local physicsResolver = PhysicsResolver.new(character, movementStats, collisionQuery)

    local FSMContextDependencies: StateMachineContextDependencies = {
        PlayerInput = playerInput,
        CollisionQuery = collisionQuery,
        PhysicsResolver = physicsResolver,
        TimerUtility = timerUtility
    }
    local stateMachineContext = StateMachineContext.new(FSMContextDependencies)
    local movementStateMachine = MovementStateMachine.new(stateMachineContext)

    local dependencies: RKMNControllerDependencies = {
        Constants = constants,
        TimerUtility = timerUtility,
        CollisionQuery = collisionQuery,
        PlayerInput = playerInput,
        MovementStateMachine = movementStateMachine,
        PhysicsResolver = physicsResolver
    }

    return dependencies
end

local function makeDebugDependencies(character: Model, inputMapper: InputMapper): RKMNControllerDependencies
    local world = game.Workspace
    local constants = CollisionConstants.new(character)
    local collisionQuery = DiagnosticControllerQuery.new(world, character, constants)
    return makeDependencies(character, constants, collisionQuery, inputMapper)
end

local function _makeProdDependencies(character: Model, inputMapper: InputMapper): RKMNControllerDependencies
    local world = game.Workspace
    local constants = CollisionConstants.new(character)
    local collisionQuery = CollisionQuery.new(world, character, constants)
    return makeDependencies(character, constants, collisionQuery, inputMapper)
end

local touchLayoutProfile = TouchLayoutProfile.new(TouchGamepadLayoutRegistry.Standard)

local function makeTouchGamepad(deviceDetector: DeviceDetector, playerInput: PlayerInputFacade): TouchGamepadPresenter
    local gamepadUI = TouchGamepadUI.new(LocalPlayer:WaitForChild("PlayerGui"))
    local positioner = MobileButtonPositioner.new()
    return TouchGamepadPresenter.new(deviceDetector, playerInput, gamepadUI, positioner, touchLayoutProfile)
end

-- The player's controls outlive any one character, so the profile is created once rather than per Setup.
local controlProfile = ControlProfile.new(KeyboardSchemes.Standard, GamepadSchemes.Standard)

local function makeControlCustomization(screenGui: ScreenGui, deviceDetector: DeviceDetector, playerInput: PlayerInputFacade): ControlCustomizationUI
    local bindingCapture = BindingCapture.new(UserInputService)
    local view = ControlCustomizationView.new(screenGui)
    return ControlCustomizationUI.new(deviceDetector, controlProfile, playerInput, bindingCapture, view, task.defer)
end

-- The player cannot move these in the touch editor, and a preset leaves them where they are.
local FIXED_TOUCH_CONTROLS: {ControlID} = { InputAction.Menu }

local function makePresetOptions(): {{Id: string, Name: string}}
    local options = {}
    for _, preset in ipairs(TouchLayoutPresets.All) do
        table.insert(options, { Id = preset.Id, Name = preset.Name })
    end
    return options
end

-- Everything the editor needs that is not the editor itself, kept together so the lot can be torn down as one.
type TouchLayoutEditing = {
    Editor: TouchLayoutEditor,
    Screen: TouchLayoutScreen,
    Canvas: TouchLayoutCanvas,
    Positioner: MobileButtonPositioner,
    GamepadUI: TouchGamepadUI
}

-- The editor's ghost controls are a second TouchGamepadUI that is never given to the player's input.
local function makeTouchLayoutEditing(deviceDetector: DeviceDetector, playerInput: PlayerInputFacade, touchGamepad: TouchGamepadPresenter): TouchLayoutEditing
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gamepadUI = TouchGamepadUI.new(playerGui)
    local positioner = MobileButtonPositioner.new()
    local canvas = TouchLayoutCanvas.new({
        GamepadUI = gamepadUI,
        Positioner = positioner,
        GetViewportSize = function()
            return gamepadUI:GetViewportSize()
        end,
        FixedControls = FIXED_TOUCH_CONTROLS,
    })
    local screen = TouchLayoutScreen.new(playerGui, canvas, makePresetOptions())
    local editor = TouchLayoutEditor.new({
        DeviceDetector = deviceDetector,
        LayoutProfile = touchLayoutProfile,
        PlayerInput = playerInput,
        TouchGamepad = touchGamepad,
        Canvas = canvas,
        Screen = screen,
        Presets = TouchLayoutPresets.All,
        FixedControls = FIXED_TOUCH_CONTROLS,
    })

    return { Editor = editor, Screen = screen, Canvas = canvas, Positioner = positioner, GamepadUI = gamepadUI }
end

-- Setup runs per character, so the previous character's device tracking and touch controls are torn down first.
-- The touch controls must go before their PlayerInputFacade does.
local activeDeviceDetector: DeviceDetector? = nil
local activeTouchGamepad: TouchGamepadPresenter? = nil
local activeControlCustomization: ControlCustomizationUI? = nil
local activeTouchLayoutEditing: TouchLayoutEditing? = nil

local function replaceControlCustomization(controlCustomization: ControlCustomizationUI): ()
    if activeControlCustomization then
        activeControlCustomization:Destroy()
    end
    activeControlCustomization = controlCustomization
end

-- The editor hands the previous character's touch controls and input back when it closes, so it goes before them.
local function destroyTouchLayoutEditing(): ()
    local editing = activeTouchLayoutEditing
    if not editing then
        return
    end

    editing.Editor:Destroy()
    editing.Screen:Destroy()
    editing.Canvas:Destroy()
    editing.Positioner:Destroy()
    editing.GamepadUI:Destroy()
    activeTouchLayoutEditing = nil
end

local function replaceTouchControls(deviceDetector: DeviceDetector, touchGamepad: TouchGamepadPresenter): ()
    if activeTouchGamepad then
        activeTouchGamepad:Destroy()
    end
    if activeDeviceDetector then
        activeDeviceDetector:Destroy()
    end
    activeDeviceDetector = deviceDetector
    activeTouchGamepad = touchGamepad
end

function RKMNControllerSetup.Setup(character: Model): RKMNController
    destroyTouchLayoutEditing()

    local screenGui = mountScreenGui()
    local world = game.Workspace

    -- The detector loads the profile's scheme for the device in use into the mapper.
    local inputMapper = InputMapper.new()
    local deviceDetector = DeviceDetector.new(UserInputService, inputMapper, controlProfile)

    local dependencies: RKMNControllerDependencies = makeDebugDependencies(character, inputMapper)
    local kinematicController = RKMNController.new(dependencies)
    kinematicController:SetInputEnabled(true)

    local touchGamepad = makeTouchGamepad(deviceDetector, dependencies.PlayerInput)
    replaceTouchControls(deviceDetector, touchGamepad)
    touchGamepad:Enable()

    local touchLayoutEditing = makeTouchLayoutEditing(deviceDetector, dependencies.PlayerInput, touchGamepad)
    activeTouchLayoutEditing = touchLayoutEditing
    touchLayoutEditing.Editor:Enable()

    local controlCustomization = makeControlCustomization(screenGui, deviceDetector, dependencies.PlayerInput)
    replaceControlCustomization(controlCustomization)
    controlCustomization:Enable()
    local debugTool = DebugFacade.new(world, screenGui, kinematicWorld, kinematicController, runServiceAdapter)
    kinematicWorld:RegisterPlayer(kinematicController)
    runServiceAdapter:Start()
    debugTool:Enable()

    return kinematicController
end

return RKMNControllerSetup
