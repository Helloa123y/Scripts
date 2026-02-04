local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local TARGET_ATTRIBUTE = "AmmoType"

-- Speicher für die Zeichnungen
local ESP_DATA = {}

local function createDrawing(type, properties)
    local d = Drawing.new(type)
    for i, v in pairs(properties) do
        d[i] = v
    end
    return d
end

local function addESP(player)
    if ESP_DATA[player] then return end
    
    ESP_DATA[player] = {
        -- Box mit etwas dickeren Linien (Thickness 2)
        Box = createDrawing("Square", {Thickness = 2, Color = Color3.new(1, 1, 1), Filled = false, Visible = false}),
        -- Text deutlich größer (Size 22) und Center auf true
        Name = createDrawing("Text", {
            Size = 30, 
            Center = true, 
            Outline = true, 
            OutlineColor = Color3.new(0, 0, 0), -- Schwarzer Rand für Lesbarkeit
            Color = Color3.new(1, 1, 1), 
            Visible = false
        })
    }
end

local function removeESP(player)
    if ESP_DATA[player] then
        ESP_DATA[player].Box:Remove()
        ESP_DATA[player].Name:Remove()
        ESP_DATA[player] = nil
    end
end

local function hasWeapon(player)
    local REQUIRED_ATTRIBUTES = {"AmmoType","damage"}
    
    local containers = {player:FindFirstChild("Backpack"), player.Character}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    -- Prüfen, ob ALLE Attribute vorhanden sind
                    local allAttributesFound = true
                    for _, attr in ipairs(REQUIRED_ATTRIBUTES) do
                        if item:GetAttribute(attr) == nil then
                            allAttributesFound = false
                            break
                        end
                    end
                    
                    if allAttributesFound then
                        return true
                    end
                end
            end
        end
    end
    return false
end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if root and hum and hum.Health > 0 then
                if not ESP_DATA[player] then addESP(player) end
                
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local data = ESP_DATA[player]

                if onScreen then
                    local isArmed = hasWeapon(player)
                    local color = isArmed and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
                    local statusText = isArmed and " [Armed]" or ""

                    -- Box Skalierung
                    local sizeX = 2000 / pos.Z
                    local sizeY = 3000 / pos.Z
                    
                    data.Box.Size = Vector2.new(sizeX, sizeY)
                    data.Box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                    data.Box.Color = color
                    data.Box.Visible = true
                    
                    -- Namen Position (etwas höher geschoben für die größere Schrift)
                    data.Name.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 25)
                    data.Name.Text = player.DisplayName .. statusText
                    data.Name.Color = color
                    data.Name.Visible = true
                else
                    data.Box.Visible = false
                    data.Name.Visible = false
                end
            else
                if ESP_DATA[player] then
                    ESP_DATA[player].Box.Visible = false
                    ESP_DATA[player].Name.Visible = false
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(removeESP)
