--!strict

local Types = require(script.Parent.Types)
local RunService = game:GetService("RunService")

local RKMNController = {}
RKMNController.__index = RKMNController

local RKMNControllerFolder = script.Parent
local CollisionConstants = require(RKMNControllerFolder.CollisionConstants)
local MovementStats = require(RKMNControllerFolder.MovementStats)
local TimerUtility = require(RKMNControllerFolder.TimerUtility)
local CollisionQuery = require(RKMNControllerFolder.CollisionQuery)
local InputController = require(RKMNControllerFolder.InputController)
local FSMContext = require(RKMNControllerFolder.FSMContext)
local MovementStateMachine = require(RKMNControllerFolder.MovementStateMachine)
local PhysicsResolver = require(RKMNControllerFolder.PhysicsResolver)

local MovementState = require(RKMNControllerFolder.MovementStateIDRegistry)

-- TODO: Add Action FSM and AnimationController back
type RKMNControllerData = {
    Character: Model,
    IsRunning: boolean,
    InputEnabled: boolean,
    
    Constants: CollisionConstants.CollisionConstants,
    TimerUtility: TimerUtility.TimerUtility,
    CollisionQuery: CollisionQuery.CollisionQuery,
    InputController: InputController.InputController,
    MovementFSM: MovementStateMachine.MovementStateMachine,
    PhysicsResolver: PhysicsResolver.PhysicsResolver,
    _connections: {RBXScriptSignal},
    _loopName: string
}

type FSMContext = FSMContext.FSMContext
type FSMContextDependencies = FSMContext.FSMContextDependencies

export type RKMNController = typeof(setmetatable({} :: RKMNControllerData, RKMNController))

function RKMNController.new(world: WorldRoot, characterModel: Model): RKMNController
    local self = {}

    self.Character = characterModel
    self.IsRunning = false
    self.InputEnabled = true

    self.Constants = CollisionConstants.new(characterModel)
    self.MovementStats = MovementStats.new()
    self.TimerUtility = TimerUtility.new()
    self.CollisionQuery = CollisionQuery.new(world, characterModel, self.Constants)
    self.InputController = InputController.new(self.TimerUtility)
    self.PhysicsResolver = PhysicsResolver.new(characterModel, self.MovementStats, self.CollisionQuery)

    local FSMContextDependencies: FSMContextDependencies = {
        InputController  = self.InputController,
        CollisionQuery = self.CollisionQuery,
        PhysicsResolver = self.PhysicsResolver,
        TimerUtility = self.TimerUtility
    }
    local FSMContext: FSMContext = FSMContext.new(FSMContextDependencies)
    self.MovementFSM = MovementStateMachine.new(FSMContext)

   

    self._connections = {}
    self._loopName = ""

    setmetatable(self, RKMNController)
    return self
end

function RKMNController.Reset(self: RKMNController): ()
	self.MovementFSM:ChangeState(MovementState.Idle)
	self.TimerUtility:FlushAll()
end

function RKMNController.Start(self: RKMNController): ()
	if self.IsRunning then
        return
    end
	self.IsRunning = true

    self:Reset()
	
	-- TODO: Factor this logic out into a dedicated KinematicController
    -- Which handles Runservice for all entities in game
	local loopName = "RKMN_KinematicLoop_" .. self.Character.Name
	
	RunService:BindToRenderStep(
		loopName, 
		Enum.RenderPriority.Character.Value, 
		function(dt)
            local humanoidRootPart: BasePart? = self.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not humanoidRootPart then
                return
            end

			self.TimerUtility:Step(dt)
			self.InputController:Poll(dt)
            self.CollisionQuery:UpdateState()

			self.MovementFSM:Update(dt)
			self.PhysicsResolver:Resolve(dt)

		end
	)
	self._loopName = loopName

end

function RKMNController.Pause(self: RKMNController)
	if not self.IsRunning then return end
	self.IsRunning = false
	
	if self._loopName then
		RunService:UnbindFromRenderStep(self._loopName)
		self._loopName = ""
	end
end

function RKMNController.SetInputEnabled(self: RKMNController, isEnabled: boolean)
	self.InputEnabled = isEnabled
	self.InputController:SetEnabled(isEnabled)
	
	if not isEnabled then
		self.InputController:FlushActiveInputs()
	end
end

function RKMNController.Destroy(self: RKMNController)
	self:Pause()
	
	self.InputController:Destroy()
	self.TimerUtility:Destroy()
	self.PhysicsResolver:Destroy()
	self.MovementFSM:Destroy()
	self.CollisionQuery:Destroy()

	table.clear(self._connections)
end


return RKMNController