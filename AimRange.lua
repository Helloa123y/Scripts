local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Whitelist sicherstellen
_G.Whitelist = _G.Whitelist or {}

-- Core Modules laden (mit Sicherheit, falls Pfade falsch sind)
local CoreUtil
local success, err = pcall(function()
	CoreUtil = require(game.ReplicatedStorage.Modules.Core.Util)
end)
if not success then warn("CoreUtil nicht gefunden!") return end

local MeleeModule
pcall(function()
	MeleeModule = require(game.ReplicatedStorage.Modules.Game.ItemTypes.Melee)
end)

-------------------------------------------------------------------
-- 1. Silent Aim Logik (Optimiert & Sicher)
-------------------------------------------------------------------
local function getTargetDirection(origin, defaultDir)
	-- Schnell-Check: Lebt der Spieler?
	local char = LocalPlayer.Character
	if not char then return defaultDir, origin, nil end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return defaultDir, origin, nil end

	local lookVector = Camera.CFrame.LookVector
	local MAX_DISTANCE = 300 -- Etwas erhöht
	local MAX_ANGLE = 45 -- FOV in Grad
	
	local bestPart = nil
	local bestScore = 0.6 

	-- Loop durch Spieler
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer or table.find(_G.Whitelist, player.Name) then continue end
		
		local pChar = player.Character
		local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
		local pHum = pChar and pChar:FindFirstChildWhichIsA("Humanoid")
		
		if pHrp and pHum and not pHum:GetAttribute("IsDead") then
			local vectorToPlayer = (pHrp.Position - origin)
			local distance = vectorToPlayer.Magnitude
			
			if distance <= MAX_DISTANCE then
				local directionUnit = vectorToPlayer.Unit
				local angle = math.deg(math.acos(lookVector:Dot(directionUnit)))
				
				if angle <= MAX_ANGLE then
					-- Score Berechnung: Nähe + Winkel
					local score = (distance / MAX_DISTANCE * 0.5) + (angle / MAX_ANGLE * 0.5)
					if score < bestScore then
						bestScore = score
						bestPart = player
					end
				end
			end
		end
	end

	-- Wenn Ziel gefunden
	if bestPart and bestPart.Character then
		local head = bestPart.Character:FindFirstChild("Head")
		if head then
			local camPos = Camera.CFrame.Position
			local dist = (head.Position - camPos).Magnitude
			local dir = (head.Position - camPos).Unit
			
			-- CRASH FIX: Stelle sicher, dass wir nicht hinter die Kamera rechnen oder ungültige Werte haben
			if dist > 6 then
				local newPos = camPos + dir * (dist - 6) -- 6 Studs vor dem Kopf starten
				return dir * 999, newPos, head
			else
				-- Zu nah? Dann nimm die Kamera-Position
				return dir * 999, camPos, head
			end
		end
	end
	
	return defaultDir, origin, nil
end

-------------------------------------------------------------------
-- 2. Der Hook für Raycasts (CRASH FIX HIER)
-------------------------------------------------------------------
local function SafeRaycastHook(arg1, arg2, arg3, arg4)
	-- arg1 = Origin, arg2 = Direction, arg3 = Params?, arg4 = Callback/FilterFunc
	
	local direction, Pos, Head = getTargetDirection(arg1, arg2)
	
	-- Filter Liste initialisieren
	local ignoreList = {LocalPlayer.Character}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList

	local resultsTable = {}
	local safetyCounter = 0 -- VERHINDERT CRASH DURCH ENDLOSSCHLEIFE

	local lastResult
	repeat
		safetyCounter = safetyCounter + 1
		
		-- Raycast ausführen
		lastResult = Workspace:Raycast(Pos or arg1, direction, rayParams)
		
		if lastResult then
			-- Treffer speichern
			table.insert(resultsTable, lastResult.Instance)
			table.insert(ignoreList, lastResult.Instance)
			rayParams.FilterDescendantsInstances = ignoreList
			
			-- Das Spiel entscheidet, ob der Raycast hier stoppen soll (z.B. bei Wänden)
			-- Wir rufen die Original-Logik (arg4) auf
			local shouldStop = false
			local s, e = pcall(function()
				shouldStop = not arg4(lastResult)
			end)
			
			if not s then 
				-- Falls die Game-Funktion crasht, brechen wir ab
				break 
			end
			
			if shouldStop then 
				break 
			end

			-- Silent Aim Fix: Wenn wir den Kopf gefunden haben, den wir wollten
			if Head and lastResult.Instance:IsDescendantOf(Head.Parent) then
				if not table.find(resultsTable, Head) then
					table.insert(resultsTable, Head)
				end
			end
		end
		
	-- CRASH PREUVENTION: Maximal 10 Durchläufe, sonst Notbremse
	until not lastResult or safetyCounter > 10 

	-- Lokalen Spieler aus den Resultaten entfernen (nur zur Sicherheit)
	if LocalPlayer.Character then
		local charIndex = table.find(resultsTable, LocalPlayer.Character)
		if charIndex then table.remove(resultsTable, charIndex) end
	end

	return resultsTable
end

-- Hook anwenden
hookfunction(CoreUtil.all_parts_on_ray, SafeRaycastHook)


-------------------------------------------------------------------
-- 3. Melee Reach Hook (Optimiert)
-------------------------------------------------------------------
if MeleeModule then
	local function SafeMeleeHook()
		local hits = {}
		local char = LocalPlayer.Character
		if not char then return hits end
		
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return hits end

		local myPos = hrp.Position
		local myLook = hrp.CFrame.LookVector
		local RANGE = 50

		for _, v in ipairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and not table.find(_G.Whitelist, v.Name) then
				local tChar = v.Character
				if tChar then
					local tHrp = tChar:FindFirstChild("HumanoidRootPart")
					local tHum =
