local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage:WaitForChild("DevPackages"):WaitForChild("TestEZ"))

-- Recursively find all *.spec modules inside Tests/
local specs = {}
local testsFolder = script.Parent
for _, descendant in ipairs(testsFolder:GetDescendants()) do
    if descendant:IsA("ModuleScript") and descendant.Name:match("\.spec") then
        table.insert(specs, descendant)
    end
end

local results = TestEZ.TestBootstrap:run(specs, TestEZ.Reporters.TextReporter)