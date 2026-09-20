local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jest = require(ReplicatedStorage.DevPackages.Jest)
local ParentFolder = script.Parent
local TestFolder = ParentFolder:WaitForChild("Tests")

local status, result = Jest.runCLI(script, {
	verbose = true,
	ci = true,
}, { TestFolder }):awaitStatus()

if status == "Rejected" then
	print("Jest run failed to execute:", result)
	-- sentinel string CI can grep for
	print("TESTS_FAILED")
	return
end

local ok = result and result.results and result.results.success
print(ok and "TESTS_PASSED" or "TESTS_FAILED")