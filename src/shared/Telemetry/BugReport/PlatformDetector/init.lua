--!strict
local PlatformDetector = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Telemetry.BugReport.BugReportDraft.Platform)

type Platform = Platform.Platform

function PlatformDetector.GetPlatform(userInputService: UserInputService, guiService: GuiService): Platform
    if guiService:IsTenFootInterface() then
        return Platform.Console
    end
    if userInputService.KeyboardEnabled then
        return Platform.PC
    end
    if userInputService.TouchEnabled then
        return Platform.Mobile
    end
    return Platform.Unknown
end

table.freeze(PlatformDetector)
return PlatformDetector
