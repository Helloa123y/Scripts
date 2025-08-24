
require(workspace:WaitForChild("ScriptLoader"):WaitForChild("ClientLoader")).RunScript()
require(workspace:WaitForChild("ScriptLoader"):WaitForChild("WeirdLoader")).RunScript()
require(workspace:WaitForChild("ScriptLoader"):WaitForChild("AH")).RunScript()
pcall(function()
	require(workspace:WaitForChild("ScriptLoader"):WaitForChild("CustomTxT")).RunScript()
end)

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    require(workspace:WaitForChild("ScriptLoader"):WaitForChild("AH")).RunScript()
end)

