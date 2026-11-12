--!strict
local BugReportSubmitter = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BugReportSubmitStatus = require(ReplicatedStorage.BugReportSubmitStatus)
local BugReportValidator = require(script.Parent.BugReportValidator)
local BugReportRow = require(script.Parent.BugReportRow)
local PlayerSessionIDRegistry = require(script.Parent.PlayerSessionIDRegistry)
local SupabaseClient = require(script.Parent.SupabaseClient)
local SupabaseConfig = require(script.Parent.SupabaseConfig)

type ReportContext = BugReportRow.ReportContext
type BugReportSubmitStatus = BugReportSubmitStatus.BugReportSubmitStatus

local TABLE_NAME = "bug_reports"
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
