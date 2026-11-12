--!strict
local BugReportSubmitter = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BugReportSubmitStatus = require(ReplicatedStorage.Telemetry.BugReport.BugReportSubmitStatus)
local BugReportValidator = require(script.Parent.BugReportValidator)
local BugReportRow = require(script.Parent.BugReportRow)
local PlayerSessionIDRegistry = require(script.Parent.Parent.Parent.PlayerSessionIDRegistry)
local SupabaseClient = require(script.Parent.Parent.Parent.SupabaseClient)
local SupabaseConfig = require(script.Parent.Parent.Parent.SupabaseConfig)

type ReportContext = BugReportRow.ReportContext
type BugReportSubmitStatus = BugReportSubmitStatus.BugReportSubmitStatus

local TABLE_NAME = "bug_reports"
local INPUT_LOG_TABLE_NAME = "input_log_entries"
local COOLDOWN_SECONDS = 30

local lastSubmitClockByPlayer: {[Player]: number} = {}

local function getPlayerPosition(player: Player): Vector3?
    local character = player.Character
    local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
    if rootPart and rootPart:IsA("BasePart") then
        return rootPart.Position
    end
    return nil
end

local function buildContext(player: Player): ReportContext
    return {
        ReportId = HttpService:GenerateGUID(false),
        UserId = player.UserId,
        Username = player.Name,
        PlaceVersion = game.PlaceVersion,
        SessionId = PlayerSessionIDRegistry.Get(player),
        Position = getPlayerPosition(player),
    }
end

local function isOnCooldown(player: Player): boolean
    local lastSubmitClock = lastSubmitClockByPlayer[player]
    return lastSubmitClock ~= nil and os.clock() - lastSubmitClock < COOLDOWN_SECONDS
end

local function attemptSubmit(player: Player, draft: any): BugReportSubmitStatus
    if isOnCooldown(player) then
        return BugReportSubmitStatus.Cooldown
    end

    local validation = BugReportValidator.Validate(draft, buildContext(player))
    if not validation.Ok or not validation.Row then
        warn(`Bug report from {player.Name} rejected: {validation.Reason}`)
        return BugReportSubmitStatus.Invalid
    end

    local configResult = SupabaseConfig.Get()
    if not configResult.Ok or not configResult.Config then
        warn(`Bug report from {player.Name} not sent: {configResult.Error}`)
        return BugReportSubmitStatus.Failed
    end

    lastSubmitClockByPlayer[player] = os.clock()
    local insertResult = SupabaseClient.Insert(configResult.Config, TABLE_NAME, { validation.Row :: any })
    if not insertResult.Ok then
        warn(`Bug report from {player.Name} not sent: {insertResult.Error} {insertResult.Body or ""}`)
        return BugReportSubmitStatus.Failed
    end

    -- The report is saved first, so a log can only ever attach to a report that exists. If the log
    -- fails, the report still counts as sent: it is worth more than the log.
    local inputLogRows = validation.InputLogRows
    if inputLogRows and #inputLogRows > 0 then
        local logResult = SupabaseClient.Insert(configResult.Config, INPUT_LOG_TABLE_NAME, inputLogRows :: any)
        if not logResult.Ok then
            warn(`Input log for bug report {validation.Row.id} not saved: {logResult.Error} {logResult.Body or ""}`)
        end
    end

    return BugReportSubmitStatus.Sent
end

function BugReportSubmitter.Submit(player: Player, draft: any): BugReportSubmitStatus
    local didRun, statusOrError = pcall(attemptSubmit, player, draft)
    if not didRun then
        warn(`Bug report from {player.Name} errored: {statusOrError}`)
        return BugReportSubmitStatus.Failed
    end
    return statusOrError :: BugReportSubmitStatus
end

Players.PlayerRemoving:Connect(function(player: Player)
    lastSubmitClockByPlayer[player] = nil
end)

table.freeze(BugReportSubmitter)
return BugReportSubmitter
