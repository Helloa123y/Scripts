local Test = function(arg1, arg2, arg3, arg4)
	local Withlist = {
		"ekincan390",
		"Temu_jisler",
		"saaed1002",
		"Mabruk_54",
		"Black_Cats187"
	}
	local function getTargetDirection()
		local LocalPlayer = game.Players.LocalPlayer
		local Character = LocalPlayer.Character
		if not Character then 
			return arg2 -- Fallback, falls kein Charakter
		end

		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
		if not HumanoidRootPart then 
			return arg2 -- Fallback, falls kein HRP
		end

		local Position = HumanoidRootPart.Position
		local Table = {}
		local Range = 800 -- Anpassbar

		-- Finde alle gültigen Spieler in Reichweite
		for _, player in game.Players:GetPlayers() do
			if player ~= LocalPlayer and not table.find(Withlist , player.Name) then
				local targetChar = player.Character
				if targetChar then
					local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
					local targetHum = targetChar:FindFirstChildWhichIsA("Humanoid")

					if targetHRP and targetHum and not targetHum:GetAttribute("IsDead") then
						local distance = (targetHRP.Position - Position).Magnitude
						if distance <= Range then
							local directionToTarget = (targetHRP.Position - Position).Unit
							local lookDot = HumanoidRootPart.CFrame.LookVector:Dot(directionToTarget)
							if math.acos(lookDot) <= 1.2 then -- ~68.7° FOV
								table.insert(Table, {
									player = player,
									distance = distance
								})
							end
						end
					end
				end
			end
		end

		-- Sortiere nach Entfernung (nächster Spieler zuerst)
		table.sort(Table, function(a, b)
			return a.distance < b.distance
		end)

		-- Wenn ein Ziel gefunden wurde, ziele auf dessen Kopf
		if Table[1] then
			local targetHead = Table[1].player.Character:FindFirstChild("Head")
			if targetHead then
				local cameraPos = workspace.CurrentCamera.CFrame.Position
				local distanceToTarget = (targetHead.Position - cameraPos).Magnitude
				local direction = (targetHead.Position - cameraPos).Unit
				local Pos = cameraPos + direction * (distanceToTarget - 6)
				print((Pos - targetHead.Position).Magnitude)
				return  direction * 500 , Pos , Table[1].player.Character:FindFirstChild("Head")
			end
		end

		return arg2 -- Fallback auf ursprüngliche Richtung
	end

	local direction , Pos , Head = getTargetDirection()
	local var49 = {}
	table.insert(var49 , game.Players.LocalPlayer.Character)
	local RaycastParams_new_result1_2 = RaycastParams.new()
	RaycastParams_new_result1_2.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams_new_result1_2.FilterDescendantsInstances = var49

	repeat
		local any_Raycast_result1 = game.Workspace:Raycast(if Pos then Pos else arg1, direction, RaycastParams_new_result1_2)
		if any_Raycast_result1 then
			table.insert(var49, any_Raycast_result1.Instance)
			RaycastParams_new_result1_2.FilterDescendantsInstances = var49
			if not arg4(any_Raycast_result1) then return end
			if Head and not table.find(var49 , Head) then
				table.insert(var49,Head)
			end
		end
	until not any_Raycast_result1
	table.remove(var49 , table.find(var49 , game.Players.LocalPlayer.Character))
	return var49
end
local old = require(game.ReplicatedStorage.Modules.Core.Util).all_parts_on_ray
print("Yes")
hookfunction(old, Test)


local OldFunction = require(game.ReplicatedStorage.Modules.Game.ItemTypes.Melee).get_hit_players

local cool = function()
    local LocalPlayer = game.Players.LocalPlayer
    local Range = 50
    local Table = {}
    local Character = LocalPlayer.Character
    if not Character then return Table end

    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return Table end

    local Position = HumanoidRootPart.Position

    for _, player in game.Players:GetPlayers() do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                local targetHum = targetChar:FindFirstChildWhichIsA("Humanoid")
                
                if targetHRP and targetHum and not targetHum:GetAttribute("IsDead") then
                    local distance = (targetHRP.Position - Position).Magnitude
                    if distance <= Range then
                        local directionToTarget = (targetHRP.Position - Position).Unit
                        local lookDot = HumanoidRootPart.CFrame.LookVector:Dot(directionToTarget)
                        if math.acos(lookDot) <= 1.2 then -- ~68.7° FOV
                            table.insert(Table, player)
                        end
                    end
                end
            end
        end
    end

    return Table
end
print("YES")
hookfunction(OldFunction, cool)

