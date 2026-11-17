local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local DebugModuleFolder = ReplicatedStorage.DebugModule
local DebugFacade = require(DebugModuleFolder.DebugFacade)
local RKMNControllerFacade = require(RKMNControllerFolder.RKMNControllerFacade)
local KinematicWorld = require(ReplicatedStorage.KinematicWorld)
local RunServiceAdapter = require(ReplicatedStorage.RunServiceAdapter)
local RenderPriorities = require(ReplicatedStorage.RenderPriorities)
local CollisionBody = require(RKMNControllerFolder.CollisionBody)
local CollisionTolerances = require(RKMNControllerFolder.CollisionTolerances)
local MovementStats = require(RKMNControllerFolder.MovementStats)
local TimerRegistry = require(RKMNControllerFolder.TimerRegistry)
local CollisionQueryFacade = require(RKMNControllerFolder.CollisionQuery.CollisionQueryFacade)
local PlayerInputFolder = ReplicatedStorage.PlayerInput
local InputAction = require(PlayerInputFolder.InputAction)
local InputMapper = require(PlayerInputFolder.InputMapper)
local InputActionMerger = require(PlayerInputFolder.InputActionMerger)
local HardwareInputSource = require(PlayerInputFolder.HardwareInputSource)
local VirtualButtonInputSource = require(PlayerInputFolder.VirtualButtonInputSource)
local ControlProfile = require(PlayerInputFolder.ControlProfile)
local KeyboardSchemes = require(PlayerInputFolder.KeyboardSchemes)
local GamepadSchemes = require(PlayerInputFolder.GamepadSchemes)
local DeviceDetector = require(PlayerInputFolder.DeviceDetector)
local PlayerInputFacade = require(PlayerInputFolder.PlayerInputFacade)
local BindingCapture = require(PlayerInputFolder.BindingCapture)
local ExclusiveScreenMediator = require(ReplicatedStorage.ExclusiveScreenMediator)
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
local TelemetryFolder = ReplicatedStorage.Telemetry
local BugReportFolder = TelemetryFolder.BugReport
local ControlPreferencesFolder = TelemetryFolder.ControlPreferences
local InputActionLog = require(TelemetryFolder.InputActionLog)
local ControlPreferencePacket = require(ControlPreferencesFolder.ControlPreferencePacket)
local ControlPreferenceReporter = require(ControlPreferencesFolder.ControlPreferenceReporter)
local BugReportDraft = require(BugReportFolder.BugReportDraft)
local BugReportPacket = require(BugReportFolder.BugReportPacket)
local BugReportButton = require(BugReportFolder.UserInterface.BugReportButton)
local BugReportScreen = require(BugReportFolder.UserInterface.BugReportScreen)
local BugReportPresenter = require(BugReportFolder.BugReportPresenter)
local PlatformDetector = require(BugReportFolder.PlatformDetector)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)
local StateMachineContext = require(RKMNControllerFolder.FSMContext)
local DiagnosticControllerQuery = require(DebugModuleFolder.DiagnosticCollisionQuery)

type TimerRegistry = TimerRegistry.TimerRegistry
type CollisionQueryFacade = CollisionQueryFacade.CollisionQueryFacade
type InputActionMerger = InputActionMerger.InputActionMerger
type DeviceDetector = DeviceDetector.DeviceDetector
type BugReportPresenter = BugReportPresenter.BugReportPresenter
type ExclusiveScreenMediator = ExclusiveScreenMediator.ExclusiveScreenMediator
type ControlPreferenceReporter = ControlPreferenceReporter.ControlPreferenceReporter
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
type RKMNControllerFacade = RKMNControllerFacade.RKMNControllerFacade
type RKMNControllerFacadeDependencies = RKMNControllerFacade.RKMNControllerFacadeDependencies
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

local function makeDependencies(character: Model, collisionQuery: CollisionQueryFacade, inputActionMerger: InputActionMerger): RKMNControllerFacadeDependencies
    local movementStats = MovementStats.new()
    local timerRegistry = TimerRegistry.new()
    local playerInput = PlayerInputFacade.new(timerRegistry, inputActionMerger)
    local physicsResolver = PhysicsResolver.new(character, movementStats, collisionQuery)

    local FSMContextDependencies: StateMachineContextDependencies = {
        PlayerInput = playerInput,
        CollisionQuery = collisionQuery,
        PhysicsResolver = physicsResolver,
        TimerRegistry = timerRegistry
    }
    local stateMachineContext = StateMachineContext.new(FSMContextDependencies)
    local movementStateMachine = MovementStateMachine.new(stateMachineContext)

    local dependencies: RKMNControllerFacadeDependencies = {
        TimerRegistry = timerRegistry,
        CollisionQuery = collisionQuery,
        PlayerInput = playerInput,
        MovementStateMachine = movementStateMachine,
        PhysicsResolver = physicsResolver
    }

    return dependencies
end

local function makeDebugDependencies(character: Model, inputActionMerger: InputActionMerger): RKMNControllerFacadeDependencies
    local world = game.Workspace
    local body = CollisionBody.new(character)
    local collisionQuery = CollisionQueryFacade.new(world, character, body, CollisionTolerances.Default)
    local diagnosticQuery = DiagnosticControllerQuery.new(collisionQuery, body, CollisionTolerances.Default)
    -- The decorator exposes the facade's whole API, but is a different class, so the type checker needs the cast.
    return makeDependencies(character, (diagnosticQuery :: any) :: CollisionQueryFacade, inputActionMerger)
end

local function _makeProdDependencies(character: Model, inputActionMerger: InputActionMerger): RKMNControllerFacadeDependencies
    local world = game.Workspace
    local body = CollisionBody.new(character)
    local collisionQuery = CollisionQueryFacade.new(world, character, body, CollisionTolerances.Default)
    return makeDependencies(character, collisionQuery, inputActionMerger)
end

local touchLayoutProfile = TouchLayoutProfile.new(TouchGamepadLayoutRegistry.Standard)

local function makeTouchGamepad(deviceDetector: DeviceDetector, playerInput: PlayerInputFacade): TouchGamepadPresenter
    local gamepadUI = TouchGamepadUI.new(LocalPlayer:WaitForChild("PlayerGui"))
    local positioner = MobileButtonPositioner.new()
    return TouchGamepadPresenter.new(deviceDetector, playerInput, gamepadUI, positioner, touchLayoutProfile)
end

-- The player's controls outlive any one character, so the profile is created once rather than per Setup.
local controlProfile = ControlProfile.new(KeyboardSchemes.Standard, GamepadSchemes.Standard)

-- Created once for the same reason, so a log attached to the merger survives respawns. Each character's
-- DeviceDetector loads the player's scheme into this mapper.
local inputMapper = InputMapper.new()
local inputActionMerger = InputActionMerger.new(
    HardwareInputSource.new(inputMapper, UserInputService),
    VirtualButtonInputSource.new()
)

-- Also once, so a report filed right after a death still has the inputs that led to it.
local bugReportInputLog = InputActionLog.new(
    inputActionMerger,
    BugReportDraft.MAX_INPUT_LOG_ENTRIES,
    BugReportDraft.MAX_INPUT_LOG_AGE_SECONDS
)

local function makeBugReport(deviceDetector: DeviceDetector, playerInput: PlayerInputFacade): BugReportPresenter
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    return BugReportPresenter.new({
        Button = BugReportButton.new(playerGui),
        Screen = BugReportScreen.new(playerGui),
        InputLog = bugReportInputLog,
        DeviceDetector = deviceDetector,
        PlayerInput = playerInput,
        GetPlatform = function()
            return PlatformDetector.GetPlatform(UserInputService, GuiService)
        end,
        Submit = function(draft)
            return BugReportPacket:Fire(draft)
        end,
        Delay = task.delay,
    })
end

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
local function makeTouchLayoutEditing(deviceDetector: DeviceDetector, playerInput: PlayerInputFacade): TouchLayoutEditing
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
local activeBugReport: BugReportPresenter? = nil
local activeScreenMediator: ExclusiveScreenMediator? = nil
local activeControlPreferenceReporter: ControlPreferenceReporter? = nil

-- It goes before the screens it watches, which fire a closing signal as they are torn down.
local function destroyScreenMediator(): ()
    if activeScreenMediator then
        activeScreenMediator:Destroy()
        activeScreenMediator = nil
    end
end

-- It replaces the old reporter only after the old screens are gone, so an edit still open at respawn is sent as they close.
local function replaceControlPreferenceReporter(reporter: ControlPreferenceReporter): ()
    if activeControlPreferenceReporter then
        activeControlPreferenceReporter:Destroy()
    end
    activeControlPreferenceReporter = reporter
end

local function replaceBugReport(bugReport: BugReportPresenter): ()
    if activeBugReport then
        activeBugReport:Destroy()
    end
    activeBugReport = bugReport
end

local function replaceControlCustomization(controlCustomization: ControlCustomizationUI): ()
    if activeControlCustomization then
        activeControlCustomization:Destroy()
    end
    activeControlCustomization = controlCustomization
end

-- The editor hands the previous character's input back when it closes, so it goes before that character's controls.
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

function RKMNControllerSetup.Setup(character: Model): RKMNControllerFacade
    destroyScreenMediator()
    destroyTouchLayoutEditing()

    local screenGui = mountScreenGui()
    local world = game.Workspace

    -- The detector loads the profile's scheme for the device in use into the mapper.
    local deviceDetector = DeviceDetector.new(UserInputService, inputMapper, controlProfile)

    local dependencies: RKMNControllerFacadeDependencies = makeDebugDependencies(character, inputActionMerger)
    local kinematicController = RKMNControllerFacade.new(dependencies)
    kinematicController:SetInputEnabled(true)

    local touchGamepad = makeTouchGamepad(deviceDetector, dependencies.PlayerInput)
    replaceTouchControls(deviceDetector, touchGamepad)
    touchGamepad:Enable()

    local touchLayoutEditing = makeTouchLayoutEditing(deviceDetector, dependencies.PlayerInput)
    activeTouchLayoutEditing = touchLayoutEditing
    touchLayoutEditing.Editor:Enable()

    local controlCustomization = makeControlCustomization(screenGui, deviceDetector, dependencies.PlayerInput)
    replaceControlCustomization(controlCustomization)
    controlCustomization:Enable()

    replaceControlPreferenceReporter(ControlPreferenceReporter.new({
        ControlProfile = controlProfile,
        TouchLayoutProfile = touchLayoutProfile,
        EditingScreens = { controlCustomization, touchLayoutEditing.Editor },
        Submit = function(report)
            ControlPreferencePacket:Fire(report)
        end,
    }))

    local bugReport = makeBugReport(deviceDetector, dependencies.PlayerInput)
    replaceBugReport(bugReport)
    bugReport:Enable()

    -- Only one of these screens is ever open; while one is, the others refuse to open and every entry point hides.
    local screenMediator = ExclusiveScreenMediator.new()
    screenMediator:AddScreen(controlCustomization)
    screenMediator:AddScreen(touchLayoutEditing.Editor)
    screenMediator:AddScreen(bugReport)
    screenMediator:AddEntryPoint(bugReport)
    screenMediator:AddEntryPoint(touchGamepad)
    activeScreenMediator = screenMediator

    local debugTool = DebugFacade.new(world, screenGui, kinematicWorld, kinematicController, runServiceAdapter)
    kinematicWorld:RegisterPlayer(kinematicController)
    runServiceAdapter:Start()
    debugTool:Enable()

    return kinematicController
end

return RKMNControllerSetup
