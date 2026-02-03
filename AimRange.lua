-- Services & Lokale Variablen
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Whitelist Initialisierung
_G.Whitelist = _G.Whitelist or {}

-------------------------------------------------------------------
-- 1. Silent Aim / Raycast Hook
-------------------------------------------------------------------
local function getTargetDirection(origin, defaultDir)
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then 
        return defaultDir 
    end

    local lookVector = Camera.CFrame.LookVector
    local MAX_DISTANCE = 2000
    local MAX_ANGLE = 45
    
    local bestPart = nil
    local bestScore = 0.6 -- Start-Schwellenwert

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or table.find(_G.Whitelist, player.Name) then continue end
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        
        if hrp and hum and not hum:GetAttribute("IsDead") then
            local directionToPart = (hrp.Position - origin)
            local distance = directionToPart.Magnitude
            
            if distance <= MAX_DISTANCE then
                local unitDir = directionToPart.Unit
                local angle = math.deg(math.acos(lookVector:Dot(unitDir)))
                
                if angle <= MAX_ANGLE then
                    -- Scoring: Niedriger ist besser
                    local score = (distance / MAX_DISTANCE * 0.6) + (angle / MAX_ANGLE * 0.4)
                    
                    if score < bestScore then
                        bestScore = score
                        bestPart = player
                    end
                end
            end
        end
    end

    if bestPart then
        local head = bestPart.Character:FindFirstChild("Head")
        if head then
            local cameraPos = Camera.CFrame.Position
            local direction = (head.Position - cameraPos).Unit
            -- Offset-Position (6 Studs vor dem Ziel)
            local hitPos = cameraPos + direction * ((head.Position - cameraPos).Magnitude - 6)
            return direction * 500, hitPos, head
        end
    end
    
    return defaultDir
end

local function NewRaycastLogic(arg1, arg2, arg3, arg4)
    local direction, Pos, targetHead = getTargetDirection(arg1, arg2)
    
    local filterList = {LocalPlayer.Character}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filterList

    local hits = {}
    local iterations = 0

    repeat
        iterations = iterations + 1
        local result = Workspace:Raycast(Pos or arg1, direction, params)
        
        if result then
            table.insert(hits, result.Instance)
            table.insert(filterList, result.Instance)
            
            -- Verhindert das Blockieren durch den Zielkopf selbst im Raycast
            if targetHead and targetHead:IsDescendantOf(result.Instance.Parent) then
                -- Logik falls Kopf getroffen
            end

            params.FilterDescendantsInstances = filterList
            if not arg4(result) then break end
        end
    until not result or iterations > 10 -- Sicherheit gegen Endlosschleifen

    return hits
end

-- Hooking der Core-Utility
local CoreUtil = require(game.ReplicatedStorage.Modules.Core.Util)
hookfunction(CoreUtil.all_parts_on_ray, NewRaycastLogic)

-------------------------------------------------------------------
-- 2. Melee Reach Hook
-------------------------------------------------------------------
local function NewMeleeHitLogic()
    local tableResult = {}
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return tableResult end

    local myPos = hrp.Position
    local myLook = hrp.CFrame.LookVector
    local RANGE = 50

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or table.find(_G.Whitelist, player.Name) then continue end
        
        local tChar = player.Character
        local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local tHum = tChar and tChar:FindFirstChildWhichIsA("Humanoid")

        if tHrp and tHum and not tHum:GetAttribute("IsDead") then
            local offset = tHrp.Position - myPos
            local distance = offset.Magnitude
            
            if distance <= RANGE then
                local dot = myLook:Dot(offset.Unit)
                if math.acos(dot) <= 1.2 then -- Sichtfeld-Check
                    table.insert(tableResult, player)
                end
            end
        end
    end
    return tableResult
end

local MeleeModule = require(game.ReplicatedStorage.Modules.Game.ItemTypes.Melee)
hookfunction(MeleeModule.get_hit_players, NewMeleeHitLogic)

print("Moon Games: Optimization Loaded.")
