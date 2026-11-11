--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local HttpTransport = require(ReplicatedStorage.HttpTransport)

describe("HttpTransport.ToResult", function()
	it("treats a 2xx response as ok and keeps its body", function()
		local result = HttpTransport.ToResult({ Success = true, StatusCode = 201, Body = "{}" })

		expect(result.Ok).toBe(true)
		expect(result.StatusCode).toBe(201)
		expect(result.Body).toBe("{}")
		expect(result.Error).toBe(nil)
	end)

	it("treats a 4xx response as a failure and explains it", function()
		local result = HttpTransport.ToResult({ Success = false, StatusCode = 401, StatusMessage = "Unauthorized", Body = "no" })

		expect(result.Ok).toBe(false)
		expect(result.StatusCode).toBe(401)
		expect(result.Error).toBe("Unauthorized")
		expect(result.Body).toBe("no")
	end)

	it("falls back to the status code when there is no status message", function()
		local result = HttpTransport.ToResult({ Success = false, StatusCode = 503 })

		expect(result.Ok).toBe(false)
		expect(result.Error).toBe("HTTP 503")
	end)

	it("does not count a 3xx response as ok", function()
		expect(HttpTransport.ToResult({ Success = false, StatusCode = 302 }).Ok).toBe(false)
	end)

	it("returns a frozen result", function()
		expect(table.isfrozen(HttpTransport.ToResult({ Success = true, StatusCode = 200 }))).toBe(true)
	end)
end)
