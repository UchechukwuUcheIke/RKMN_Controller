local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNController = require(RKMNControllerFolder.RKMNController)

local KinematicWorld = {}
KinematicWorld.__index = KinematicWorld

type RKMNController = RKMNController.RKMNController

type KinematicWorldData = {
	_players: {RKMNController},
    _runserviceBindName: string,
    _isRunning: boolean,
}

type KinematicWorldPrototype = typeof(KinematicWorld)

export type KinematicWorld = typeof(setmetatable(
	{} :: KinematicWorldData,
	{} :: KinematicWorldPrototype
))

function KinematicWorld.new(): KinematicWorld
	local self = setmetatable({}, KinematicWorld)
	
	self._players = {}
	self._isRunning = false
    self._runserviceBindName = "MasterKinematicLoop"
	return self
end

function KinematicWorld.RegisterPlayer(self: KinematicWorld, controller: RKMNController): ()
	table.insert(self._players, controller)
end

function KinematicWorld.Start(self: KinematicWorld): ()
	if self._isRunning then 
        return 
    end
	self._isRunning = true
	
	RunService:BindToRenderStep(
		self._runserviceBindName,
		Enum.RenderPriority.Character.Value, 
		function(dt)
			self:_stepWorld(dt)
		end
	)
end

function KinematicWorld.Stop(self: KinematicWorld): ()
    if not self._isRunning then 
        return 
    end

    RunService:UnbindFromRenderStep(self._runserviceBindName)

    self._isRunning = false
end

function KinematicWorld.StepWorld(self: KinematicWorld, deltaTime: number)
	for _, playerController: RKMNController in ipairs(self._players) do
		self:_processEntity(playerController, deltaTime)
	end
end

function KinematicWorld._processEntity(self: KinematicWorld, entityController: RKMNController, deltaTime: number)
	if entityController.TimerUtility then 
        entityController.TimerUtility:Step(deltaTime) 
    end

	if entityController.InputController then 
        entityController.InputController:Poll(deltaTime)
    end
	
	if entityController.CollisionQuery then
        entityController.CollisionQuery:UpdateState()
    end
	
	if entityController.MovementStateMachine then
        entityController.MovementStateMachine:Update(deltaTime)
    end
	
	if entityController.PhysicsResolver then
        entityController.PhysicsResolver:Resolve(deltaTime)
    end
end

function KinematicWorld.Destroy(self: KinematicWorld): ()
    self:Stop()
    table.clear(self._players)
    setmetatable(self :: any, nil)    
    table.freeze(self)
end

table.freeze(KinematicWorld)

return KinematicWorld
