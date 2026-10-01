local RunService = game:GetService("RunService")

local KinematicWorld = {}
KinematicWorld.__index = KinematicWorld

function KinematicWorld.new()
	local self = setmetatable({}, KinematicWorld)
	
	-- Data Arrays (The "Entities")
	self.Players = {}
	self.Enemies = {}
	self.Projectiles = {}
	self.Items = {}
	
	self.IsRunning = false
	return self
end

-- Entities are just tables containing your existing DI modules
function KinematicWorld:RegisterPlayer(controllerObject)
	table.insert(self.Players, controllerObject)
end

function KinematicWorld:RegisterEnemy(controllerObject)
	table.insert(self.Enemies, controllerObject)
end

function KinematicWorld:Start()
	if self.IsRunning then return end
	self.IsRunning = true
	
	-- ONE single RenderStep connection for the entire game
	RunService:BindToRenderStep(
		"MasterKinematicLoop", 
		Enum.RenderPriority.Character.Value, 
		function(dt)
			self:_stepWorld(dt)
		end
	)
end

function KinematicWorld:_stepWorld(dt)
	-- 1. Process Players First (Inputs are read, physics are applied)
	for _, player in ipairs(self.Players) do
		self:_processEntity(player, dt)
	end
	
	-- 2. Process Enemies (AI reads where the player just moved)
	for _, enemy in ipairs(self.Enemies) do
		self:_processEntity(enemy, dt)
	end
	
	-- 3. Process Projectiles & Items
	for _, proj in ipairs(self.Projectiles) do
		self:_processEntity(proj, dt)
	end
end

-- The universal execution pipeline
function KinematicWorld:_processEntity(entity, dt)
	-- If it has timers, step them
	if entity.Timers then entity.Timers:Step(dt) end
	
	-- If it has an Input or AI controller, poll it
	if entity.Input then entity.Input:Poll(dt) end
	
	-- Update spatial awareness
	if entity.Collision then entity.Collision:Update(entity.Character.PrimaryPart.CFrame) end
	
	-- Run State Machines
	if entity.MovementFSM then entity.MovementFSM:Update(dt) end
	if entity.ActionFSM then entity.ActionFSM:Update(dt) end
	
	-- Apply Kinematics
	if entity.Physics then entity.Physics:Resolve(dt) end
end

return KinematicWorld
