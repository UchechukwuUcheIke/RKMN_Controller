--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local PacketIDs = require(ReplicatedStorage.PacketIDs)

describe("PacketIDs", function()
	it("gives every packet a different name, since the Packet library hands back the first packet made under a name", function()
		local seen = {}

		for key, packetID in pairs(PacketIDs) do
			expect(seen[packetID]).toBeNil()
			seen[packetID] = key
		end
	end)

	it("uses each key as its own name, so a rename cannot leave the two disagreeing", function()
		for key, packetID in pairs(PacketIDs) do
			expect(packetID).toBe(key)
		end
	end)

	it("is frozen", function()
		expect(table.isfrozen(PacketIDs)).toBe(true)
	end)
end)
