--!strict
local SupabaseClient = {}

local HttpService = game:GetService("HttpService")
local HttpTransport = require(script.Parent.HttpTransport)

type HttpResult = HttpTransport.HttpResult
type Key = string | Secret

export type SupabaseConfig = {
    Url: string,
    AnonKey: Key
}

local REST_PATH = "/rest/v1/"

local function bearerFor(key: Key): Key
    if typeof(key) == "string" then
        return "Bearer " .. key
    end
    return key:AddPrefix("Bearer ")
end

local function failure(message: string): HttpResult
    return table.freeze({
        Ok = false,
        Error = message,
    })
end

function SupabaseClient.BuildTableUrl(config: SupabaseConfig, tableName: string): string
    assert(tableName:match("^[%w_]+$") ~= nil, `Invalid Supabase table name: {tableName}`)

    local baseUrl = config.Url:gsub("/+$", "")
    return baseUrl .. REST_PATH .. tableName
end

function SupabaseClient.BuildInsertHeaders(config: SupabaseConfig): {[string]: Key}
    return {
        ["apikey"] = config.AnonKey,
        ["Authorization"] = bearerFor(config.AnonKey),
        ["Content-Type"] = "application/json",
        ["Prefer"] = "return=minimal",
    }
end

function SupabaseClient.Insert(config: SupabaseConfig, tableName: string, rows: {{[string]: any}}): HttpResult
    if #rows == 0 then
        return failure("Nothing to insert")
    end

    local didEncode, bodyOrError = pcall(HttpService.JSONEncode, HttpService, rows)
    if not didEncode then
        return failure(`Could not encode rows: {bodyOrError}`)
    end

    return HttpTransport.Post(
        SupabaseClient.BuildTableUrl(config, tableName),
        bodyOrError :: string,
        SupabaseClient.BuildInsertHeaders(config)
    )
end

table.freeze(SupabaseClient)
return SupabaseClient
