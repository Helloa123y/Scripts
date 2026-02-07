_G.Withelist =  if _G.Withelist then _G.Withelist else {}



_G.FOVCircle = Drawing.new("Circle")
_G.FOVCircle.Thickness = 2
_G.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
_G.FOVCircle.Filled = false
_G.FOVCircle.Transparency = 0.5
_G.FOVCircle.Radius = _G.Config.FOVRadius -- Das ist die Größe deines "Aimbot-Fensters"
_G.FOVCircle.Visible = true

_G.FOVCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)

_G.currentPing = 10
task.spawn(function()
	while task.wait(5) do
		local stats = game:GetService("Stats")
		_G.currentPing = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end
end)




local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Status-Variablen
local followActive = false
local lockedTarget = nil
local preTeleportCFrame = nil

-- Funktion zum Beenden des Follows
local function disableFollow()
	followActive = false
	lockedTarget = nil
	_G.targetPlayer = nil
	local char = game.Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if root and preTeleportCFrame then
		root.CFrame = preTeleportCFrame
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end
	preTeleportCFrame = nil
end


local function getBestTarget()
	local bestPlayer = nil
	local bestScore = math.huge
	local finalPredictedPos = nil

	local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, plr in ipairs(game.Players:GetPlayers()) do
		if plr == LocalPlayer or table.find(_G.Withelist or {}, plr.Name) then continue end

		local char = plr.Character
		local head = char and char:FindFirstChild("Head")
		local hum = char and char:FindFirstChild("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		if head and hum and root and hum.Health > 0 then

			-- 1. Distanz Check (Welt)
			local distToPlayer = (root.Position - Camera.CFrame.Position).Magnitude
			if distToPlayer > _G.Config.MaxDistance then continue end

			-- 2. FOV Check (Bildschirm)
			local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
			if onScreen then
				local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

				if distToMouse <= _G.Config.FOVRadius then

					-- :: DAS SCORING SYSTEM :: --
					-- Wir kombinieren Maus-Nähe und Distanz zum Gegner.
					-- Score = (MausAbstand) + (WeltAbstand * Gewichtung)
					local score = distToMouse + (distToPlayer * _G.Config.DistanceWeight)

					-- HP Logik: Leichte Strafe für Low HP, aber kein Ausschluss!
					if _G.Config.AvoidLowHP and hum.Health < _G.Config.LowHPThreshold then
						score = score + _G.Config.LowHPPenalty
					end

					if score < bestScore then
						bestScore = score
						bestPlayer = plr
						local dynamicPrediction = _G.Config.DefaultPrediction
						if _G.Config.UsePrediction then
							for _, step in ipairs(_G.Config.PingPredictionTable) do
								if _G.currentPing <= step[1] then
									dynamicPrediction = step[2]
									break
								end
							end
						else
							dynamicPrediction = 0
						end

						finalPredictedPos = head.Position + (root.Velocity * dynamicPrediction)
					end
				end
			end
		end
	end

	return bestPlayer, finalPredictedPos
end


UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.M then
		local char = game.Players.LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		-- Toggle OFF
		if followActive then
			disableFollow()
		else
			-- Toggle ON (Nur wenn Health > 30)
			if hum and hum.Health > 30 and root then
				-- Target suchen (deine getBestTarget Funktion)
				local targetPlayer, _ = getBestTarget()
				_G.targetPlayer = targetPlayer
				if targetPlayer then
					lockedTarget = targetPlayer
					preTeleportCFrame = root.CFrame
					followActive = true
				end
			end
		end
	end
end)

-- Haupt-Loop
RunService.Heartbeat:Connect(function()
	local myChar = game.Players.LocalPlayer.Character
	local myHum = myChar and myChar:FindFirstChild("Humanoid")
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

	-- 1. Abbruch-Bedingungen prüfen
	if followActive then
		-- Wenn ich selbst low HP bin oder sterbe
		if not myHum or myHum.Health <= 30 then
			disableFollow()
			return
		end

		-- Wenn das Target weg ist (Leaved, Character gelöscht, Tot)
		if not lockedTarget or not lockedTarget.Parent or not lockedTarget.Character or not lockedTarget.Character:FindFirstChild("Humanoid") or lockedTarget.Character.Humanoid.Health <= 0 then
			disableFollow()
			return
		end

		-- 2. Teleport ausführen (Target-Lock)
		local targetRoot = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot and myRoot then
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0)
			myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end
	end
end)


local Test = function(arg1, arg2, arg3, arg4)
	local Camera = workspace.CurrentCamera
	local LocalPlayer = game.Players.LocalPlayer

	-- :: HILFSFUNKTION: Das beste Ziel finden :: --
	local function getBestTarget()
		local bestPlayer = nil
		local bestScore = math.huge
		local finalPredictedPos = nil

		local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

		for _, plr in ipairs(game.Players:GetPlayers()) do
			if plr == LocalPlayer or table.find(_G.Withelist or {}, plr.Name) then continue end
			if _G.targetPlayer then
				if plr.Name ~= _G.targetPlayer.Name then continue end
			end
			local char = plr.Character
			local head = char and char:FindFirstChild("Head")
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")

			if head and hum and root and hum.Health > 0 then

				-- 1. Distanz Check (Welt)
				local distToPlayer = (root.Position - Camera.CFrame.Position).Magnitude
				if distToPlayer > _G.Config.MaxDistance then continue end

				-- 2. FOV Check (Bildschirm)
				local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
				if onScreen or _G.targetPlayer then
					local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

					if distToMouse <= _G.Config.FOVRadius or _G.targetPlayer then

						-- :: DAS SCORING SYSTEM :: --
						-- Wir kombinieren Maus-Nähe und Distanz zum Gegner.
						-- Score = (MausAbstand) + (WeltAbstand * Gewichtung)
						local score = distToMouse + (distToPlayer * _G.Config.DistanceWeight)

						-- HP Logik: Leichte Strafe für Low HP, aber kein Ausschluss!
						if _G.Config.AvoidLowHP and hum.Health < _G.Config.LowHPThreshold then
							score = score + _G.Config.LowHPPenalty
						end

						if score < bestScore then
							bestScore = score
							bestPlayer = plr

							local dynamicPrediction = _G.Config.DefaultPrediction

							if _G.Config.UsePrediction then
								for _, step in ipairs(_G.Config.PingPredictionTable) do
									if _G.currentPing <= step[1] then
										dynamicPrediction = step[2]
										break
									end
								end
							else
								dynamicPrediction = 0
							end
							
							if _G.targetPlayer then
								dynamicPrediction = dynamicPrediction + 0.15 -- Der "Latency-Vorstoß"
							end
							
							finalPredictedPos = head.Position + (root.Velocity * dynamicPrediction)
						end
					end
				end
			end
		end

		return bestPlayer, finalPredictedPos
	end

	-- 1. Ziel suchen
	local targetPlayer, predictedPos = getBestTarget()

	-- 2. Wenn Ziel gefunden -> Silent Aim (Spoofing)
	if targetPlayer and predictedPos then
		local targetHead = targetPlayer.Character:FindFirstChild("Head")
		if not targetHead then return {} end

		-- Wir nehmen die Position des Ziels als Trefferpunkt
		local hitPos = predictedPos

		-- :: VISUAL BEAM :: --
		task.spawn(function()
			local beam = Instance.new("Part")
			beam.Parent = workspace
			beam.Anchored = true
			beam.CanCollide = false
			beam.Material = Enum.Material.Neon
			beam.Color = Color3.fromRGB(255, 0, 0)
			beam.Transparency = 0.5

			-- Distanzberechnung für den Strahl
			local beamDist = (arg1 - hitPos).Magnitude
			beam.Size = Vector3.new(0.05, 0.05, beamDist)
			beam.CFrame = CFrame.lookAt(arg1, hitPos) * CFrame.new(0, 0, -beamDist/2)
			game:GetService("Debris"):AddItem(beam, 0.1) 
		end)

		-- 3. FAKE RESULT (Über globale Variablen gesteuert)
		local fakeResult = {
			Instance = targetHead,
			Position = hitPos,
			Normal = Vector3.new(0, 1, 0),
			Material = Enum.Material.Plastic,
			-- Standardmäßig echte Distanz berechnen
			Distance = (arg1 - hitPos).Magnitude 
		}

		fakeResult.Distance = 0.1

		-- Den Treffer direkt in die Engine füttern
		arg4(fakeResult)

		-- Rückgabe an das Waffensystem (Head + Torso für bessere Hit-Registration)
		local upperTorso = targetPlayer.Character:FindFirstChild("UpperTorso")
		return {targetHead, upperTorso or targetHead}
	end

	-- 3. Fallback: Normaler Raycast (wenn kein Ziel im FOV)
	-- Hier nutzen wir den ursprünglichen Raycast des Spiels, damit man normal schießen kann
	local ignoreList = {LocalPlayer.Character}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList

	-- Die Richtung aus den Argumenten nutzen (wohin du wirklich zielst)
	local originalDirection = arg2 
	-- Falls arg2 keine Direction ist, müssen wir raten. Meist ist arg2 direction.
	-- Wenn arg2 nil ist, nutzen wir Kamera Blickrichtung
	if typeof(originalDirection) ~= "Vector3" then 
		originalDirection = Camera.CFrame.LookVector * 2000 
	end

	local result = workspace:Raycast(arg1, originalDirection, rayParams)

	-- Wenn der normale Raycast etwas trifft, geben wir das zurück
	if result then
		if not arg4(result) then return {} end -- Original Logik beibehalten
		return {result.Instance}
	end

	return {}
end


local old = require(game.ReplicatedStorage.Modules.Core.Util).all_parts_on_ray
print("Yes")
--hookfunction(old, Test)


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
						table.insert(Table, player)
					end
				end
			end
		end
	end

	return Table
end
print("YES")
hookfunction(OldFunction, cool)  -- ayrifinalk
