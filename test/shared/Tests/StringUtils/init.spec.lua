--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local UtilityFolder = ReplicatedStorage.Utility
local StringUtils = require(UtilityFolder.StringUtils)

describe("StringUtils.TrimWhitespace", function()
	it("removes whitespace from both ends", function()
		expect(StringUtils.TrimWhitespace("  hello  ")).toBe("hello")
	end)

	it("removes tabs and newlines", function()
		expect(StringUtils.TrimWhitespace("\t\nhello\n\t")).toBe("hello")
	end)

	it("keeps whitespace inside the text", function()
		expect(StringUtils.TrimWhitespace("  hello   world  ")).toBe("hello   world")
	end)

	it("returns text without surrounding whitespace unchanged", function()
		expect(StringUtils.TrimWhitespace("hello")).toBe("hello")
	end)

	it("turns whitespace-only text into an empty string", function()
		expect(StringUtils.TrimWhitespace("   \t\n ")).toBe("")
	end)

	it("returns an empty string for an empty string", function()
		expect(StringUtils.TrimWhitespace("")).toBe("")
	end)
end)
