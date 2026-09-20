-- Must be a standard Script (not a LocalScript or ModuleScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Create the Plugin Toolbar and Button
local toolbar = plugin:CreateToolbar("Jest Testing")
local runButton = toolbar:CreateButton(
    "Run Tests", 
    "Execute all Jest test suites", 
    "" -- Optional: Add an rbxassetid:// link here for a custom icon
)

-- 2. Bind the execution to the button click
runButton.Click:Connect(function()
    print("🚀 Starting Jest tests...")
    
    -- Locate Jest and your test folders
    -- Adjust these paths based on your project's structure (e.g., ReplicatedStorage.Packages.Jest)
    local Jest = require(ReplicatedStorage.DevPackages.Jest)
    local testRoots = { 
        ReplicatedStorage.Tests
    }

    -- 3. Execute the CLI
    local status, result = Jest.runCLI(
        ReplicatedStorage, -- or wherever makes sense as your project root
        {
            verbose = true,
            ci = false,
        },
        testRoots
    ):await()
    
    if status and result.results.success then
        print("✅ All Jest tests passed.")
    else
        warn("❌ Jest tests failed or encountered errors.")
        if not status then
            warn("Promise rejected:", result)
        end
    end
end)