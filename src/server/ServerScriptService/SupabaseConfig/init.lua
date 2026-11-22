--!strict
local SupabaseConfig = {}

local HttpService = game:GetService("HttpService")
local SupabaseClient = require(script.Parent.SupabaseClient)

type SupabaseClientConfig = SupabaseClient.SupabaseConfig

export type ConfigResult = {
    Ok: boolean,
    Config: SupabaseClientConfig?,
    Error: string?
}

local PROJECT_URL = "https://aqmoeezwjmkngbuenmlk.supabase.co"
local ANON_KEY_SECRET_NAME = "anon_public_key"

local function failure(message: string): ConfigResult
    return table.freeze({
        Ok = false,
        Error = message,
    })
end

local function getSecret(name: string): (Secret?, string?)
    local didGet, secretOrError = pcall(HttpService.GetSecret, HttpService, name)
    if not didGet then
        return nil, `Secret "{name}" could not be read: {secretOrError}`
    end
    return secretOrError :: Secret, nil
end

function SupabaseConfig.Get(): ConfigResult
    local anonKey, keyError = getSecret(ANON_KEY_SECRET_NAME)
    if not anonKey then
        return failure(keyError or "Anon key secret missing")
    end

    return table.freeze({
        Ok = true,
        Config = table.freeze({
            Url = PROJECT_URL,
            AnonKey = anonKey,
        }),
    })
end

table.freeze(SupabaseConfig)
return SupabaseConfig
