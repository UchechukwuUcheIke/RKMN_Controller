--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage.Combat
local DataFolder = CombatFolder.Data
local ProjectileFolder = CombatFolder.Projectile
local WeaponFolder = CombatFolder.Weapon
local HitboxRegistry = require(CombatFolder.Hitbox.HitboxRegistry)
local HitResolver = require(CombatFolder.Hitbox.HitResolver)
local HurtboxRegistry = require(CombatFolder.Hurtbox.HurtboxRegistry)
local MegaBuster = require(WeaponFolder.MegaBuster)
local ProjectileIDRegistry = require(ProjectileFolder.ProjectileIDRegistry)
local ProjectileModelPlacer = require(ProjectileFolder.ProjectileModelPlacer)
local ProjectileSimulation = require(ProjectileFolder.ProjectileSimulation)
local RKMNController = require(ReplicatedStorage.RKMNController.RKMNController)
local RenderPriorities = require(ReplicatedStorage.RenderPriorities)
local RunServiceAdapter = require(ReplicatedStorage.RunServiceAdapter)
local Team = require(DataFolder.Team)
local WeaponFacade = require(WeaponFolder.WeaponFacade)
local WeaponRegistry = require(WeaponFolder.WeaponRegistry)
local WallQuery = require(ProjectileFolder.WallQuery)

type ProjectileID = ProjectileIDRegistry.ProjectileID
type RKMNController = RKMNController.RKMNController

-- Where a shot leaves the character, relative to the character's center, mirrored by facing.
local MUZZLE_OFFSET = Vector2.new(2, 0.5)

local PlayerCombatSetup = {}

export type PlayerCombat = {
	Weapon: MegaBuster.MegaBuster,
	Projectiles: ProjectileSimulation.ProjectileSimulation,
	HurtboxRegistry: HurtboxRegistry.HurtboxRegistry,
	Destroy: (self: PlayerCombat) -> (),
}

local function createProjectileModel(id: ProjectileID): Model
	local template = ReplicatedStorage.Assets.Projectile:FindFirstChild(id)
	assert(template and template:IsA("Model"), `No projectile model named {id} in Assets.Projectile`)
	return template:Clone()
end

-- Builds the player's combat around an existing controller: the Mega Buster, the shots it fires,
-- and the frame that moves them. Other fighters' hurtboxes go in the returned HurtboxRegistry.
function PlayerCombatSetup.Setup(controller: RKMNController, character: Model): PlayerCombat
	local world = workspace

	local shotsFolder = Instance.new("Folder")
	shotsFolder.Name = "Projectiles"
	shotsFolder.Parent = world

	local hurtboxes = HurtboxRegistry.new()
	local hitboxes = HitboxRegistry.new()
	local resolver = HitResolver.new(hitboxes, hurtboxes)
	local walls = WallQuery.new(world)
	local projectiles = ProjectileSimulation.new(hitboxes, walls)
	local modelPlacer = ProjectileModelPlacer.new(projectiles, createProjectileModel, shotsFolder)

	local weapons = WeaponFacade.new(WeaponRegistry.new())
	local weapon = MegaBuster.new(projectiles, Players.LocalPlayer.UserId, Team.Player, function()
		local rootPosition = (character.PrimaryPart :: BasePart).Position
		local center = Vector2.new(rootPosition.X, rootPosition.Y)
		local direction = controller.PhysicsResolver.FacingDirection
		local muzzle = center + Vector2.new(MUZZLE_OFFSET.X * direction.X, MUZZLE_OFFSET.Y)
		-- Against a wall the muzzle can be inside it, where the shot would fly through.
		return {
			Position = walls:FindPointBeforeWall(center, muzzle),
			Direction = direction,
		}
	end)
	weapons:Register(weapon)

	local playerInput = controller.PlayerInput
	local pressConnection = playerInput.OnTriggerPressed:Connect(function()
		weapon:PressTrigger()
	end)
	local releaseConnection = playerInput.OnTriggerReleased:Connect(function()
		weapon:ReleaseTrigger()
	end)

	local frame = RunServiceAdapter.new("PlayerCombatFrame", RenderPriorities.Combat, function(dt: number)
		weapons:Update(dt)
		projectiles:Advance(dt)
		projectiles:Settle(resolver:Resolve())
		modelPlacer:Update()
	end)
	frame:Start()

	local combat: PlayerCombat
	combat = {
		Weapon = weapon,
		Projectiles = projectiles,
		HurtboxRegistry = hurtboxes,
		Destroy = function()
			frame:Destroy()
			pressConnection:Disconnect()
			releaseConnection:Disconnect()
			modelPlacer:Destroy()
			projectiles:Destroy()
			walls:Destroy()
			resolver:Destroy()
			shotsFolder:Destroy()
		end,
	}
	return combat
end

return PlayerCombatSetup
