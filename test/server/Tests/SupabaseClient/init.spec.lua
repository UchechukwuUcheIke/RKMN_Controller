--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local SupabaseClient = require(ServerScriptService.Server.SupabaseClient)

local CONFIG = { Url = "https://abc.supabase.co", AnonKey = "anon-key" }

describe("SupabaseClient.BuildTableUrl", function()
	it("points at the table's REST endpoint", function()
		expect(SupabaseClient.BuildTableUrl(CONFIG, "bug_reports")).toBe("https://abc.supabase.co/rest/v1/bug_reports")
	end)

	it("ignores trailing slashes on the project url", function()
		local config = { Url = "https://abc.supabase.co//", AnonKey = "k" }

		expect(SupabaseClient.BuildTableUrl(config, "logs")).toBe("https://abc.supabase.co/rest/v1/logs")
	end)

	it("rejects table names that could change the path", function()
		expect(function()
			SupabaseClient.BuildTableUrl(CONFIG, "logs?select=*")
		end).toThrow()
	end)
end)

describe("SupabaseClient.BuildInsertHeaders", function()
	it("sends the key as both apikey and bearer token", function()
		local headers = SupabaseClient.BuildInsertHeaders(CONFIG)

		expect(headers["apikey"]).toBe("anon-key")
		expect(headers["Authorization"]).toBe("Bearer anon-key")
	end)

	it("asks for JSON in and an empty response out", function()
		local headers = SupabaseClient.BuildInsertHeaders(CONFIG)

		expect(headers["Content-Type"]).toBe("application/json")
		expect(headers["Prefer"]).toBe("return=minimal")
	end)
end)

describe("SupabaseClient.Insert", function()
	it("refuses an empty insert without sending anything", function()
		local result = SupabaseClient.Insert(CONFIG, "logs", {})

		expect(result.Ok).toBe(false)
		expect(result.Error).toBe("Nothing to insert")
	end)

	it("reports rows that cannot be encoded instead of throwing", function()
		local result = SupabaseClient.Insert(CONFIG, "logs", { { bad = function() end } })

		expect(result.Ok).toBe(false)
		expect(result.StatusCode).toBe(nil)
	end)
end)
