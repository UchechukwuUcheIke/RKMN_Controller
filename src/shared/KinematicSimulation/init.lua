local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RKMNControllerFolder = ReplicatedStorage.RKMNController
local RKMNControllerFacade = require(RKMNControllerFolder.RKMNControllerFacade)

local KinematicSimulation = {}
KinematicSimulation.__index = KinematicSimulation
KinematicSimulation.ClassName = "KinematicSimulation"

type RKMNControllerFacade = RKMNControllerFacade.RKMNControllerFacade

type KinematicSimulationData = {
	_players: {RKMNControllerFacade},
}

type KinematicSimulationPrototype = typeof(KinematicSimulation)

export type KinematicSimulation = typeof(setmetatable(
	{} :: KinematicSimulationData,
	{} :: KinematicSimulationPrototype
))

function KinematicSimulation.new(): KinematicSimulation
	local self = setmetatable({}, KinematicSimulation)
	self._players = {}
	return self
end

function KinematicSimulation.RegisterPlayer(self: KinematicSimulation, controller: RKMNControllerFacade): ()
	table.insert(self._players, controller)
end

function KinematicSimulation.Step(self: KinematicSimulation, deltaTime: number)
	for _, playerController: RKMNControllerFacade in ipairs(self._players) do
		playerController:Update(deltaTime)
	end
end

function KinematicSimulation.Destroy(self: KinematicSimulation): ()
    table.clear(self._players)
    setmetatable(self :: any, nil)    
    table.freeze(self)
end

table.freeze(KinematicSimulation)

return KinematicSimulation