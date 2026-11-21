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
		playerController:Update(deltaTime)
	end
end

function KinematicWorld.Destroy(self: KinematicWorld): ()
    table.clear(self._players)
    setmetatable(self :: any, nil)    
    table.freeze(self)
end

table.freeze(KinematicWorld)

return KinematicWorld