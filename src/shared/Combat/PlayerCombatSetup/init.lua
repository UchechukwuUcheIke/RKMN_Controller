--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local WeaponFolder = CombatFolder.Weapon
local CombatSimulation = require(CombatFolder.CombatSimulation)
local XBuster = require(WeaponFolder.XBuster)
local RKMNControllerFacade = require(ReplicatedStorage.RKMNController.RKMNControllerFacade)
local Team = require(DataFolder.Team)

type CombatSimulation = CombatSimulation.CombatSimulation
type RKMNControllerFacade = RKMNControllerFacade.RKMNControllerFacade

-- Where a shot leaves the character, relative to the character's center, mirrored by facing.
local MUZZLE_OFFSET = Vector2.new(2, 0.5)

local PlayerCombatSetup = {}

export type PlayerCombat = {
	Weapon: XBuster.XBuster,
	Destroy: (self: PlayerCombat) -> (),
}

-- Adds the player's combat to the simulation, around an existing controller: the X-Buster and
-- the trigger that fires it.
function PlayerCombatSetup.Setup(
	simulation: CombatSimulation,
	controller: RKMNControllerFacade,
	character: Model
): PlayerCombat
	local weapon = XBuster.new(simulation.Projectiles, Players.LocalPlayer.UserId, Team.Player, function()
		local rootPosition = (character.PrimaryPart :: BasePart).Position
		local center = Vector2.new(rootPosition.X, rootPosition.Y)
		local direction = controller.PhysicsResolver:GetFacingDirection()
		local muzzle = center + Vector2.new(MUZZLE_OFFSET.X * direction.X, MUZZLE_OFFSET.Y)
		-- Against a wall the muzzle can be inside it, where the shot would fly through.
		return {
			Position = simulation.Walls:FindPointBeforeWall(center, muzzle),
			Direction = direction,
		}
	end)
	simulation.Weapons:Register(weapon)

	local playerInput = controller.PlayerInput
	local pressConnection = playerInput.OnTriggerPressed:Connect(function()
		weapon:PressTrigger()
	end)
	local releaseConnection = playerInput.OnTriggerReleased:Connect(function()
		weapon:ReleaseTrigger()
	end)

	local combat: PlayerCombat
	combat = {
		Weapon = weapon,
		Destroy = function()
			pressConnection:Disconnect()
			releaseConnection:Disconnect()
			simulation.Weapons:Unregister(weapon)
		end,
	}
	return combat
end

return PlayerCombatSetup
