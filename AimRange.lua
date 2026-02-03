_G.Withelist =  if _G.Withelist then _G.Withelist else {}

local Test = function(arg1, arg2, arg3, arg4)
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
        
        local origin = Character.HumanoidRootPart.Position
        local lookVector = workspace.CurrentCamera.CFrame.LookVector
        
        local MAX_DISTANCE = 200
        local MAX_ANGLE = 45
        local FADE_DURATION = 0.15
        
        local bestPart = nil
        local bestScore = 0.6
        for _, part in ipairs(game.Players:GetPlayers()) do
            local plr = part
            if not part.Character or not part.Character:FindFirstChild("HumanoidRootPart") then continue end
            	local part = part.Character.HumanoidRootPart
        	local directionToPart = (part.Position - origin)
        	local distance = directionToPart.Magnitude
        	if distance > MAX_DISTANCE then continue end
        	local angle = math.deg(math.acos(lookVector:Dot(directionToPart.Unit)))
        	if angle > MAX_ANGLE then continue end
        	local normalizedDistance = distance / MAX_DISTANCE
        	local normalizedAngle = angle / MAX_ANGLE
        	local score = (normalizedDistance * 0.6) + (normalizedAngle * 0.4) 
            
        	if score < bestScore and not part.Parent.Humanoid:GetAttribute("IsDead") and not table.find(_G.Withelist, plr.Name) then
        		bestScore = score
        		bestPart = plr
        	end
        end
        
        -- Wenn ein Ziel gefunden wurde, ziele auf dessen Kopf
        if bestPart then
        	local targetHead = bestPart.Character:FindFirstChild("Head")
        	if targetHead then
        		local cameraPos = workspace.CurrentCamera.CFrame.Position
        		local distanceToTarget = (targetHead.Position - cameraPos).Magnitude
        		local direction = (targetHead.Position - cameraPos).Unit
        		local Pos = cameraPos + direction * (distanceToTarget - 6)
        		print((Pos - targetHead.Position).Magnitude)
        		local Head = bestPart.Character.Head
        		return  direction * 500 , Pos , Head
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
       if player ~= LocalPlayer and not table.find(_G.Withelist, player.Name) then
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
