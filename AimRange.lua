_G.Withelist =  if _G.Withelist then _G.Withelist else {}

local Test = function(arg1, arg2, arg3, arg4)
	local function getTargetDirection()
    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then 
        return arg2 
    end
    
    local origin = Character.HumanoidRootPart.Position
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    local lookVector = cameraCFrame.LookVector
    
    local MAX_DISTANCE = 500
    local MAX_ANGLE = 45
    
    local bestPart = nil
    local bestScore = 2.0 -- Erhöht, damit Ziele innerhalb des FOV zuverlässig gefunden werden

    for _, plr in ipairs(game.Players:GetPlayers()) do
        -- 1. Basis-Checks (Selbst-Check, Charakter-Existenz, Whitelist)
        if plr == LocalPlayer or table.find(_G.Withelist, plr.Name) then continue end
        
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        -- 2. Vitalitäts-Check
        if not hrp or not hum or hum:GetAttribute("IsDead") then continue end
        
        -- 3. Distanz-Check
        local directionToPart = (hrp.Position - origin)
        local distance = directionToPart.Magnitude
        if distance > MAX_DISTANCE then continue end
        
        -- 4. Winkel-Check (FOV)
        local unitDir = directionToPart.Unit
        local dot = lookVector:Dot(unitDir)
        -- math.clamp verhindert Abstürze bei minimalen Rechenfehlern außerhalb von -1 bis 1
        local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
        
        if angle > MAX_ANGLE then continue end
        
        -- 5. Scoring
        local normalizedDistance = distance / MAX_DISTANCE
        local normalizedAngle = angle / MAX_ANGLE
        local score = (normalizedDistance * 0.4) + (normalizedAngle * 0.6) -- Fokus mehr auf Bildschirmmitte
        
        if score < bestScore then
            bestScore = score
            bestPart = plr
        end
    end

    -- Wenn ein Ziel gefunden wurde, ziele auf dessen Kopf
    if bestPart and bestPart.Character then
        local targetHead = bestPart.Character:FindFirstChild("Head")
        if targetHead then
            local cameraPos = cameraCFrame.Position
            local headPos = targetHead.Position
            local offsetDirection = (headPos - cameraPos).Unit
            local distanceToTarget = (headPos - cameraPos).Magnitude
            
            -- Pos wird 6 Studs vor dem Kopf gesetzt (für Silent Aim Trajektorie)
            local Pos = cameraPos + offsetDirection * math.max(0, distanceToTarget - 6)
            
            return offsetDirection * 500, Pos, targetHead
        end
    end
    
    return arg2
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
    local Range = 300
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
