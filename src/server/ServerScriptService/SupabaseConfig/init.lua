--!strict
local SupabaseConfig = {}

local SupabaseClient = require(script.Parent.SupabaseClient)

type SupabaseClientConfig = SupabaseClient.SupabaseConfig

export type ConfigResult = {
    Ok: boolean,
    Config: SupabaseClientConfig?,
    Error: string?
}

local CREDENTIALS_MODULE_NAME = "SupabaseCredentials"
local SETUP_HINT = `Copy {CREDENTIALS_MODULE_NAME}.lua.example to {CREDENTIALS_MODULE_NAME}.lua and fill it in.`

local function failure(message: string): ConfigResult
    return table.freeze({
        Ok = false,
        Error = message,
    })
end

local function isNonEmptyString(value: any): boolean
    return typeof(value) == "string" and value ~= ""
end

function SupabaseConfig.Get(): ConfigResult
    local credentialsModule = script:FindFirstChild(CREDENTIALS_MODULE_NAME)
    if not credentialsModule or not credentialsModule:IsA("ModuleScript") then
        return failure(`Supabase credentials not found. {SETUP_HINT}`)
    end

    local didLoad, credentials = pcall(require, credentialsModule)
    if not didLoad then
        return failure(`Supabase credentials failed to load: {credentials}`)
    end

    if typeof(credentials) ~= "table" or not isNonEmptyString(credentials.Url) or not isNonEmptyString(credentials.AnonKey) then
        return failure(`Supabase credentials need a non-empty Url and AnonKey. {SETUP_HINT}`)
    end

    return table.freeze({
        Ok = true,
        Config = table.freeze({
            Url = credentials.Url :: string,
            AnonKey = credentials.AnonKey :: string,
        }),
    })
end

table.freeze(SupabaseConfig)
return SupabaseConfig
