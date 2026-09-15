local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RKMNController = ReplicatedStorage:WaitForChild("RKMNController")
local Direction = require(RKMNController.Direction)
local MovementConstants = require(RKMNController:WaitForChild("MovementConstants"))
local CollisionQuery = require(RKMNController:WaitForChild("CollisionQuery"))
local MockWorld = require(ReplicatedStorage:WaitForChild("MockWorld"):WaitForChild("MockWorld"))

type Properties = MockWorld.Properties
type Direction = Direction.Direction

return function()
	local MovementConstants = {
		HitboxSize = Vector3.new(2, 4, 2),
		GroundCheckDistance = 3,
		WallCheckDistance = 3,
		SkinWidth = 0.05,
		MaxSlopeAngle = 45,
	}

    local TestWorld = MockWorld.new()

	local Character
	local PrimaryPart
	local Collision

	local function calculateCFrameNextToPart(part: Part): CFrame

		local xOffset: number = MovementConstants.HitboxSize.X/2 
					+ part.Size.X/2 + MovementConstants.SkinWidth / 2

		local resultCFrame: CFrame = part.CFrame - Vector3.new(xOffset, 0, 0)

		return resultCFrame
	end

	local function calculateCFrameAbovePart(part: Part): CFrame
		local resultCFrame: CFrame = part.CFrame
			+ Vector3.new(
				0, 
				MovementConstants.HitboxSize.Y/2 
					+ MovementConstants.GroundCheckDistance/2
					+ part.Size.Y/2,
				0
		)

		return resultCFrame
	end


	beforeEach(function()
		Character = TestWorld:SpawnCharacter()
		PrimaryPart = Character.PrimaryPart :: BasePart
		Collision = CollisionQuery.new(TestWorld, Character, MovementConstants)
	end)

	afterEach(function()
		if Collision then
			Collision:Destroy()
			Collision = nil
		end
		if TestWorld then
			TestWorld:Clear()
		end
	end)

	describe("CollisionQuery Instantiation", function()
		it("creates an ungrounded query", function()
			expect(Collision:IsGrounded()).to.equal(false)
		end)

		it("starts with no current floor part", function()
			expect(Collision.CurrentFloorPart).to.equal(nil)
		end)

		it("starts with a zero floor normal", function()
			expect(Collision.FloorNormal).to.equal(Vector3.zero)
		end)

		it("starts with an identity moving platform delta", function()
			expect(Collision.MovingPlatformDelta).to.equal(CFrame.identity)
		end)

		it("stores the character primary part", function()
			expect(Collision._primaryPart).to.equal(PrimaryPart)
		end)

		it("stores the supplied movement constants", function()
			expect(Collision._constants).to.equal(MovementConstants)
		end)

		it("calculates the maximum slope dot from MaxSlopeAngle", function()
			local expected = math.cos(math.rad(MovementConstants.MaxSlopeAngle))

			expect(Collision._maxSlopeDot).to.equal(expected)
		end)

		it("creates raycast parameters that exclude the character", function()
			local excludedInstances = Collision._raycastParams.FilterDescendantsInstances

			expect(#excludedInstances).to.equal(1)
			expect(excludedInstances[1]).to.equal(Character)
		end)

		it("requires the character to have a PrimaryPart", function()
			Collision:Destroy()

			Character:Destroy()
			Character = nil
			PrimaryPart = nil

			local characterWithoutPrimaryPart = Instance.new("Model")
			characterWithoutPrimaryPart.Name = "CharacterWithoutPrimaryPart"

			local success, errorMessage = pcall(function()
				CollisionQuery.new(
					TestWorld,
					characterWithoutPrimaryPart,
					MovementConstants
				)
			end)

			characterWithoutPrimaryPart:Destroy()

			expect(success).to.equal(false)
			expect(string.find(errorMessage, "PrimaryPart")).never.to.equal(nil)
		end)
	end)
    
	describe("_isWalkable", function()
		it("considers a perfectly flat upward normal walkable", function()
			expect(Collision:_isWalkable(Vector3.yAxis)).to.equal(true)
		end)

		it("considers a perfectly vertical wall normal not walkable", function()
			expect(Collision:_isWalkable(Vector3.xAxis)).to.equal(false)
		end)

		it("considers a downward normal not walkable", function()
			expect(Collision:_isWalkable(-Vector3.yAxis)).to.equal(false)
		end)

		it("considers a slope above the maximum angle not walkable", function()
			local angle = math.rad(MovementConstants.MaxSlopeAngle + 10)
			local normal = Vector3.new(
				math.sin(angle),
				math.cos(angle),
				0
			)

			expect(Collision:_isWalkable(normal)).to.equal(false)
		end)


		it("considers a slope below the maximum angle walkable", function()
			local angle = math.rad(MovementConstants.MaxSlopeAngle - 10)
			local normal = Vector3.new(
				math.sin(angle),
				math.cos(angle),
				0
			)

			expect(Collision:_isWalkable(normal)).to.equal(true)
		end)
	end)
	
	describe("UpdateState", function()
		it("becomes grounded when standing over a walkable floor", function()

			local properties: Properties = {
				Size = Vector3.new(20, 0.1, 20),
				CFrame = CFrame.new(0, 0, 0)
				}
			local floor = TestWorld:SpawnPart(properties)

			local testCFrame = calculateCFrameAbovePart(floor)

			Collision:UpdateState(testCFrame)

			expect(Collision:IsGrounded()).to.equal(true)
			expect(Collision.CurrentFloorPart).to.equal(floor)
			expect(Collision.FloorNormal).to.equal(Vector3.yAxis)
		end)

		it("remains ungrounded when there is no floor", function()
			PrimaryPart.CFrame = CFrame.new(0, 2, 0)

			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision:IsGrounded()).to.equal(false)
			expect(Collision.CurrentFloorPart).to.equal(nil)
			expect(Collision.FloorNormal).to.equal(Vector3.zero)
			expect(Collision.MovingPlatformDelta).to.equal(CFrame.identity)
		end)

		it("does not consider a wall to be ground", function()

			local properties: Properties = {
				Size = Vector3.new(1, 10, 10),
				CFrame = CFrame.new(3, 2, 0)
				}
			TestWorld:SpawnPart(properties)

			PrimaryPart.CFrame = CFrame.new(0, 2, 0)

			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision:IsGrounded()).to.equal(false)
			expect(Collision.CurrentFloorPart).to.equal(nil)
			expect(Collision.FloorNormal).to.equal(Vector3.zero)
		end)

		it("stores the floor part after landing", function()

			local properties: Properties = {
				Size = Vector3.new(20, 1, 20),
				CFrame = CFrame.new(0, 20, 0)
			}
			local floor = TestWorld:SpawnPart(properties)

			PrimaryPart.CFrame = calculateCFrameAbovePart(floor)

			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision.CurrentFloorPart).to.equal(floor)
		end)

		it("resets floor state after leaving the floor", function()

			local properties: Properties = {
				Size = Vector3.new(20, 0.1, 20),
				CFrame = CFrame.new(0, -0.5, 0)
			}
			local floor = TestWorld:SpawnPart(properties)

			PrimaryPart.CFrame = calculateCFrameAbovePart(floor)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision:IsGrounded()).to.equal(true)

			PrimaryPart.CFrame = CFrame.new(0, 20, 0)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision:IsGrounded()).to.equal(false)
			expect(Collision.CurrentFloorPart).to.equal(nil)
			expect(Collision.FloorNormal).to.equal(Vector3.zero)
			expect(Collision.MovingPlatformDelta).to.equal(CFrame.identity)
		end)

		it("returns identity platform delta when first landing on a platform", function()

			local properties: Properties = {
				Size = Vector3.new(20, 0.1, 20),
				CFrame = CFrame.new(0, -0.5, 0)
			}
			local floor = TestWorld:SpawnPart(properties)

			PrimaryPart.CFrame = calculateCFrameAbovePart(floor)

			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision.MovingPlatformDelta).to.equal(CFrame.identity)
		end)

		it("tracks the delta of the same floor part across frames", function()
			local properties: Properties = {
				Size = Vector3.new(20, 0.1, 20),
				CFrame = CFrame.new(0, -0.5, 0)
			}
			local floor = TestWorld:SpawnPart(properties)

			PrimaryPart.CFrame = calculateCFrameAbovePart(floor)
			Collision:UpdateState(PrimaryPart.CFrame)
			expect(Collision:IsGrounded()).to.equal(true)
			expect(Collision.MovingPlatformDelta).to.equal(CFrame.identity)

			local previousCFrame = floor.CFrame
			local newCFrame = previousCFrame + Vector3.new(3, 0, 2)

			floor.CFrame = newCFrame

			Collision:UpdateState(PrimaryPart.CFrame)
			expect(Collision:IsGrounded()).to.equal(true)
			print("hitPart is our floor:", Collision.CurrentFloorPart == floor)
			local expectedDelta = newCFrame * previousCFrame:Inverse()

			expect(Collision.MovingPlatformDelta).to.equal(expectedDelta)
		end)
		
		it("resets the platform delta when switching floor parts", function()

			local firstProperties: Properties = {
				Size = Vector3.new(6, 1, 6),
				CFrame = CFrame.new(-5, -0.5, 0)
			}
			local firstFloor = TestWorld:SpawnPart(firstProperties)

			local secondProperties: Properties = {
				Size = Vector3.new(6, 1, 6),
				CFrame = CFrame.new(5, -0.5, 0)
			}
			local secondFloor = TestWorld:SpawnPart(secondProperties)


			PrimaryPart.CFrame = calculateCFrameAbovePart(firstFloor)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision.CurrentFloorPart).to.equal(firstFloor)

			PrimaryPart.CFrame = calculateCFrameAbovePart(secondFloor)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision.CurrentFloorPart).to.equal(secondFloor)
			expect(Collision.MovingPlatformDelta).to.equal(CFrame.identity)
		end)
	end)

	describe("IsGrounded", function()
		it("reflects the internal grounded state", function()

			expect(Collision:IsGrounded()).to.equal(false)
			
			local properties: Properties = {
				Size = Vector3.new(20, 1, 20),
				CFrame = CFrame.new(0, -0.5, 0)
			}
			local floor = TestWorld:SpawnPart(properties)

			PrimaryPart.CFrame = calculateCFrameAbovePart(floor)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision:IsGrounded()).to.equal(true)
		end)
	end)

	describe("CheckWallContact", function()
		it("returns false when there is no obstruction", function()
			PrimaryPart.CFrame = CFrame.new(0, 2, 0)

			local hasContact = Collision:CheckWallContact(
				PrimaryPart.CFrame,
				Vector3.xAxis
			)

			expect(hasContact).to.equal(false)
		end)

		it("returns true when a wall is directly in the movement direction", function()

			local properties: Properties = {
				Size = Vector3.new(1, 10, 10),
				CFrame = CFrame.new(2.5, 2, 0)
			}
			local wall = TestWorld:SpawnPart(properties)

			PrimaryPart.CFrame = calculateCFrameNextToPart(wall)

			local hasContact = Collision:CheckWallContact(
				PrimaryPart.CFrame,
				Direction.Right
			)

			expect(hasContact).to.equal(true)
		end)

		it("returns false when the collision normal is walkable", function()

			--TODO: Make more representative test
		end)
	end)
	
	describe("GetSweepResolution", function()
		it("returns an empty resolution for zero velocity", function()
			local resolution = Collision:GetSweepResolution(
				CFrame.new(0, 2, 0),
				Vector3.zero
			)

			expect(resolution.safeDelta).to.equal(Vector3.zero)
			expect(resolution.hitFloor).to.equal(false)
			expect(resolution.hitWall).to.equal(false)
		end)

		it("returns the complete delta when nothing is hit", function()
			local velocityDelta = Vector3.new(2, 0, 0)

			local resolution = Collision:GetSweepResolution(
				CFrame.new(0, 2, 0),
				velocityDelta
			)

			expect(resolution.safeDelta).to.equal(velocityDelta)
			expect(resolution.hitFloor).to.equal(false)
			expect(resolution.hitWall).to.equal(false)
		end)

		it("clamps movement when a wall is hit", function()

			local properties: Properties = {
				Size = Vector3.new(1, 10, 10),
				CFrame = CFrame.new(4, 2, 0)
			}
			TestWorld:SpawnPart(properties)

			local velocityDelta = Vector3.new(10, 0, 0)

			local resolution = Collision:GetSweepResolution(
				CFrame.new(0, 2, 0),
				velocityDelta
			)

			expect(resolution.hitWall).to.equal(true)
			expect(resolution.hitFloor).to.equal(false)
			expect(resolution.safeDelta.Magnitude < velocityDelta.Magnitude).to.equal(true)
			expect(resolution.safeDelta.Magnitude > 0).to.equal(true)
		end)

		it("reports a walkable floor collision", function()

			local properties: Properties = {
				Size = Vector3.new(20, 1, 20),
				CFrame = CFrame.new(0, -0.5, 0)
			}
			local wall = TestWorld:SpawnPart(properties)

			local velocityDelta = Vector3.new(0, -10, 0)

			local resolution = Collision:GetSweepResolution(
				CFrame.new(0, 8, 0),
				velocityDelta
			)

			expect(resolution.hitFloor).to.equal(true)
			expect(resolution.hitWall).to.equal(false)
			expect(resolution.safeDelta.Magnitude < velocityDelta.Magnitude).to.equal(true)
			expect(resolution.safeDelta.Magnitude >= 0).to.equal(true)
		end)

		it("backs off the collision distance by SkinWidth", function()

			local properties: Properties = {
				Size = Vector3.new(1, 10, 10),
				CFrame = CFrame.new(4, 2, 0)
			}
			local wall = TestWorld:SpawnPart(properties)

			local velocityDelta = Vector3.new(10, 0, 0)

			local resolution = Collision:GetSweepResolution(
				CFrame.new(0, 2, 0),
				velocityDelta
			)

			-- The exact collision distance is determined by Roblox's
			-- spatial query, but safeDelta should never reach the
			-- collision point itself.
			expect(resolution.safeDelta.Magnitude < velocityDelta.Magnitude).to.equal(
				true
			)
		end)

		it("preserves the movement direction when clamping a sweep", function()

			local properties: Properties = {
				Size = Vector3.new(1, 10, 10),
				CFrame = CFrame.new(4, 2, 0)
			}
			local wall = TestWorld:SpawnPart(properties)

			local velocityDelta = Vector3.new(10, 0, 0)

			local resolution = Collision:GetSweepResolution(
				CFrame.new(0, 2, 0),
				velocityDelta
			)

			expect(resolution.safeDelta.X > 0).to.equal(true)
			expect(resolution.safeDelta.Y).to.equal(0)
			expect(resolution.safeDelta.Z).to.equal(0)
		end)

		--[[
		it("clamps a collision to zero when the skin width exceeds the hit distance", function()
			-- TODO: At some point I need to seriously think about how these tests
			-- are written -- this is too cumbersome
			local properties: Properties = {
				Size = Vector3.new(1, 10, 10),
				CFrame = CFrame.new(1.05, 2, 0)
			}
			local wall = TestWorld:SpawnPart(properties)

			local velocityDelta = Vector3.new(2, 0, 0)

			local primaryPartCFrame = wall.CFrame - MovementConstants.SkinWidth/2

			local resolution = Collision:GetSweepResolution(
				primaryPartCFrame,
				velocityDelta
			)

			expect(resolution.hitWall).to.equal(true)
			expect(resolution.safeDelta.Magnitude).to.equal(0)
		end)
		]]--
	end)
	--[[
	describe("Destroy", function()
		it("clears the current floor part", function()
			local floor = createPart(
				"TestFloor",
				Vector3.new(20, 1, 20),
				CFrame.new(0, -0.5, 0)
			)

			PrimaryPart.CFrame = CFrame.new(0, 2, 0)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision.CurrentFloorPart).to.equal(floor)

			Collision:Destroy()

			expect(Collision.CurrentFloorPart).to.equal(nil)
		end)

		it("clears the last floor part", function()
			createPart(
				"TestFloor",
				Vector3.new(20, 1, 20),
				CFrame.new(0, -0.5, 0)
			)

			PrimaryPart.CFrame = CFrame.new(0, 2, 0)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision._lastFloorPart).never.to.equal(nil)

			Collision:Destroy()

			expect(Collision._lastFloorPart).to.equal(nil)
		end)

		it("clears the last floor CFrame", function()
			createPart(
				"TestFloor",
				Vector3.new(20, 1, 20),
				CFrame.new(0, -0.5, 0)
			)

			PrimaryPart.CFrame = CFrame.new(0, 2, 0)
			Collision:UpdateState(PrimaryPart.CFrame)

			expect(Collision._lastFloorCFrame).never.to.equal(nil)

			Collision:Destroy()

			expect(Collision._lastFloorCFrame).to.equal(nil)
		end)

		it("clears raycast filter instances", function()
			Collision:Destroy()

			expect(
				#Collision._raycastParams.FilterDescendantsInstances
			).to.equal(0)
		end)
	end)
    ]]--
end
