local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SweepResolution = require(
	ReplicatedStorage
		:WaitForChild("RKMNController")
		:WaitForChild("SweepResolution")
)

return function()
	describe("SweepResolution Instantiation", function()
		it("creates a resolution with default values", function()
			local resolution = SweepResolution.new()

			expect(resolution.safeDelta).to.equal(Vector3.zero)
			expect(resolution.hitFloor).to.equal(false)
			expect(resolution.hitWall).to.equal(false)
		end)

		it("defaults safeDelta to Vector3.zero when nil is provided", function()
			local resolution = SweepResolution.new(nil, true, true)

			expect(resolution.safeDelta).to.equal(Vector3.zero)
			expect(resolution.hitFloor).to.equal(true)
			expect(resolution.hitWall).to.equal(true)
		end)

		it("defaults hitFloor to false when nil is provided", function()
			local resolution = SweepResolution.new(Vector3.new(1, 2, 3), nil, true)

			expect(resolution.safeDelta).to.equal(Vector3.new(1, 2, 3))
			expect(resolution.hitFloor).to.equal(false)
			expect(resolution.hitWall).to.equal(true)
		end)

		it("defaults hitWall to false when nil is provided", function()
			local resolution = SweepResolution.new(Vector3.new(1, 2, 3), true, nil)

			expect(resolution.safeDelta).to.equal(Vector3.new(1, 2, 3))
			expect(resolution.hitFloor).to.equal(true)
			expect(resolution.hitWall).to.equal(false)
		end)

		it("preserves an explicitly provided safeDelta", function()
			local safeDelta = Vector3.new(10, 20, 30)

			local resolution = SweepResolution.new(safeDelta)

			expect(resolution.safeDelta).to.equal(safeDelta)
		end)

		it("preserves an explicitly provided hitFloor value", function()
			local resolution = SweepResolution.new(Vector3.zero, true)

			expect(resolution.hitFloor).to.equal(true)
		end)

		it("preserves an explicitly provided hitWall value", function()
			local resolution = SweepResolution.new(Vector3.zero, false, true)

			expect(resolution.hitWall).to.equal(true)
		end)

		it("preserves all explicitly provided values", function()
			local safeDelta = Vector3.new(-5, 12, 7)

			local resolution = SweepResolution.new(
				safeDelta,
				true,
				true
			)

			expect(resolution.safeDelta).to.equal(safeDelta)
			expect(resolution.hitFloor).to.equal(true)
			expect(resolution.hitWall).to.equal(true)
		end)

		it("allows false to be explicitly provided for hitFloor", function()
			local resolution = SweepResolution.new(Vector3.zero, false, true)

			expect(resolution.hitFloor).to.equal(false)
			expect(resolution.hitWall).to.equal(true)
		end)

		it("allows false to be explicitly provided for hitWall", function()
			local resolution = SweepResolution.new(Vector3.zero, true, false)

			expect(resolution.hitFloor).to.equal(true)
			expect(resolution.hitWall).to.equal(false)
		end)
	end)
end