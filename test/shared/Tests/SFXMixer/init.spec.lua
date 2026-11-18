--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local SFXMixer = require(ReplicatedStorage.SFXEmitter.SFXMixer)

describe("SFXMixer", function()
	local parent
	local mixer

	beforeEach(function()
		parent = Instance.new("Folder")
		mixer = SFXMixer.new(parent)
	end)

	afterEach(function()
		parent:Destroy()
	end)

	it("should create its SoundGroup under the given parent", function()
		expect(mixer:GetSoundGroup().Parent).toBe(parent)
		expect(mixer:GetSoundGroup().Name).toBe("SFXGroup")
	end)

	it("should set the group's volume", function()
		mixer:SetVolume(0.4)

		expect(mixer:GetSoundGroup().Volume).toBeCloseTo(0.4)
	end)

	it("should never set a negative volume", function()
		mixer:SetVolume(-1)

		expect(mixer:GetSoundGroup().Volume).toBe(0)
	end)

	it("should silence the group while muted and restore the volume after", function()
		mixer:SetVolume(0.6)

		mixer:SetMuted(true)
		expect(mixer:GetSoundGroup().Volume).toBe(0)

		mixer:SetMuted(false)
		expect(mixer:GetSoundGroup().Volume).toBeCloseTo(0.6)
	end)

	it("should remember a volume set while muted", function()
		mixer:SetMuted(true)
		mixer:SetVolume(0.3)
		expect(mixer:GetSoundGroup().Volume).toBe(0)

		mixer:SetMuted(false)

		expect(mixer:GetSoundGroup().Volume).toBeCloseTo(0.3)
	end)

	it("should remove its SoundGroup when destroyed", function()
		local group = mixer:GetSoundGroup()

		mixer:Destroy()

		expect(group.Parent).toBeNil()
	end)
end)
