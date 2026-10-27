local Players = game:GetService("Players")
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
local InputMapper = require(PlayerInputFolder.InputMapper)
local InputSchemeRegistry = require(PlayerInputFolder.InputSchemeRegistry)
local PlayerInputFacade = require(PlayerInputFolder.PlayerInputFacade)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)
local StateMachineContext = require(RKMNControllerFolder.FSMContext)
local DiagnosticControllerQuery = require(DebugModuleFolder.DiagnosticCollisionQuery)

type CollisionConstants = CollisionConstants.CollisionConstants
type TimerUtility = TimerUtility.TimerUtility
type CollisionQuery = CollisionQuery.CollisionQuery
type PlayerInputFacade = PlayerInputFacade.PlayerInputFacade
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

local function makeDependencies(character: Model, constants: CollisionConstants, collisionQuery: CollisionQuery): RKMNControllerDependencies
    local movementStats = MovementStats.new()
    local timerUtility = TimerUtility.new()
    local inputMapper = InputMapper.new()
    inputMapper:LoadControlScheme(InputSchemeRegistry.Standard)
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

local function makeDebugDependencies(character: Model): RKMNControllerDependencies
    local world = game.Workspace
    local constants = CollisionConstants.new(character)
    local collisionQuery = DiagnosticControllerQuery.new(world, character, constants)
    return makeDependencies(character, constants, collisionQuery)
end

local function _makeProdDependencies(character: Model): RKMNControllerDependencies
    local world = game.Workspace
    local constants = CollisionConstants.new(character)
    local collisionQuery = CollisionQuery.new(world, character, constants)
    return makeDependencies(character, constants, collisionQuery)
end

function RKMNControllerSetup.Setup(character: Model): RKMNController
    local screenGui = mountScreenGui()
    local world = game.Workspace

    local dependencies: RKMNControllerDependencies = makeDebugDependencies(character)
    local kinematicController = RKMNController.new(dependencies)
    kinematicController:SetInputEnabled(true)
    local debugTool = DebugFacade.new(world, screenGui, kinematicWorld, kinematicController, runServiceAdapter)
    kinematicWorld:RegisterPlayer(kinematicController)
    runServiceAdapter:Start()
    debugTool:Enable()

    return kinematicController
end

return RKMNControllerSetup
