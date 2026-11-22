--!strict
local ControlPreferenceSubmitter = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ControlPreferenceRateLimiter = require(script.Parent.ControlPreferenceRateLimiter)
local ControlPreferenceReportContext = require(script.Parent.ControlPreferenceReportContext)
local ControlPreferenceRow = require(script.Parent.ControlPreferenceRow)
local ControlPreferenceValidator = require(script.Parent.ControlPreferenceValidator)
local PlayerSessionIDRegistry = require(script.Parent.Parent.Parent.PlayerSessionIDRegistry)
local SupabaseClient = require(script.Parent.Parent.Parent.SupabaseClient)
local SupabaseConfig = require(script.Parent.Parent.Parent.SupabaseConfig)

type ControlPreferenceReportContext = ControlPreferenceReportContext.ControlPreferenceReportContext
type ControlPreferenceRow = ControlPreferenceRow.ControlPreferenceRow
type ValidationResult = ControlPreferenceValidator.ValidationResult

local REPORT_TABLE_NAME = "control_preference_reports"
local BINDING_TABLE_NAME = "control_binding_entries"
local TOUCH_TABLE_NAME = "touch_control_entries"
local COOLDOWN_SECONDS = 5
local MAX_REPORTS_PER_PLAYER = 20

local rateLimiter = ControlPreferenceRateLimiter.new(COOLDOWN_SECONDS, MAX_REPORTS_PER_PLAYER)

local function insertEntries(config: SupabaseClient.SupabaseConfig, tableName: string, rows: {any}, reportId: string)
    local hasRowsToSubmit = #rows > 0
    if not hasRowsToSubmit then
        return
    end

    local result = SupabaseClient.Insert(config, tableName, rows)
    if not result.Ok then
        warn(`Control preference {reportId}: {tableName} not saved: {result.Error} {result.Body or ""}`)
    end
end

local function validateReport(player: Player, report: unknown): ValidationResult?
    local context = ControlPreferenceReportContext.new(
        HttpService:GenerateGUID(false),
        game.PlaceVersion,
        PlayerSessionIDRegistry.Get(player)
    )

    local validation = ControlPreferenceValidator.Validate(report, context)
    if not validation.Ok or not validation.Row then
        warn(`Control preference from {player.Name} rejected: {validation.Reason}`)
        return nil
    end
    return validation
end

local function loadConfig(player: Player): SupabaseClient.SupabaseConfig?
    local configResult = SupabaseConfig.Get()
    if not configResult.Ok or not configResult.Config then
        warn(`Control preference from {player.Name} not sent: {configResult.Error}`)
        return nil
    end
    return configResult.Config
end

local function insertReport(player: Player, config: SupabaseClient.SupabaseConfig, row: ControlPreferenceRow): boolean
    local result = SupabaseClient.Insert(config, REPORT_TABLE_NAME, { row :: any })
    if not result.Ok then
        warn(`Control preference from {player.Name} not sent: {result.Error} {result.Body or ""}`)
        return false
    end
    return true
end

local function attemptSubmit(player: Player, report: unknown): boolean
    if not rateLimiter:TryAccept(player) then
        return false
    end

    local validation = validateReport(player, report)
    if not validation then
        return false
    end

    local config = loadConfig(player)
    if not config then
        return false
    end

    local row = validation.Row :: ControlPreferenceRow
    if not insertReport(player, config, row) then
        return false
    end

    insertEntries(config, BINDING_TABLE_NAME, validation.BindingRows or {}, row.id)
    insertEntries(config, TOUCH_TABLE_NAME, validation.TouchRows or {}, row.id)
    return true
end

function ControlPreferenceSubmitter.Submit(player: Player, report: unknown): boolean
    local didRun, wasSent = pcall(attemptSubmit, player, report)
    if not didRun then
        warn(`Control preference from {player.Name} errored: {wasSent}`)
        return false
    end
    return wasSent :: boolean
end

Players.PlayerRemoving:Connect(function(player: Player)
    rateLimiter:Forget(player)
end)

table.freeze(ControlPreferenceSubmitter)
return ControlPreferenceSubmitter
