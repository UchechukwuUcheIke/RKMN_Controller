local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNControllerFacade = require(RKMNControllerFolder.RKMNControllerFacade)

local KinematicWorld = {}
KinematicWorld.__index = KinematicWorld
KinematicWorld.ClassName = "KinematicWorld"

type RKMNControllerFacade = RKMNControllerFacade.RKMNControllerFacade

type KinematicWorldData = {
	_players: {RKMNControllerFacade},
}

type KinematicWorldPrototype = typeof(KinematicWorld)

export type KinematicWorld = typeof(setmetatable(
	{} :: KinematicWorldData,
	{} :: KinematicWorldPrototype
))

function KinematicWorld.new(): KinematicWorld
	local self = setmetatable({}, KinematicWorld)
	self._players = {}
	return self
end

function KinematicWorld.RegisterPlayer(self: KinematicWorld, controller: RKMNControllerFacade): ()
	table.insert(self._players, controller)
end

function KinematicWorld.StepWorld(self: KinematicWorld, deltaTime: number)
	for _, playerController: RKMNControllerFacade in ipairs(self._players) do
		self:_processEntity(playerController, deltaTime)
	end
end

function KinematicWorld._processEntity(self: KinematicWorld, entityController: RKMNControllerFacade, deltaTime: number)
	if entityController.TimerRegistry then 
        entityController.TimerRegistry:Step(deltaTime) 
    end

	if entityController.PlayerInput then 
        entityController.PlayerInput:Poll(deltaTime)
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
    table.clear(self._players)
    setmetatable(self :: any, nil)    
    table.freeze(self)
end

table.freeze(KinematicWorld)

return KinematicWorld