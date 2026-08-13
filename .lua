-- // GiG AIM) + Universal Aimbot (Q Toggle Only) //

-- // Configuration //

local LibraryUrl = "https://raw.githubusercontent.com/Vovabro46/trash/refs/heads/main/Test.lua"
local Success, Library = pcall(function()
    return loadstring(game:HttpGet(LibraryUrl))()
end)

if not Success or not Library then
    print("Failed to load library")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // ESP Settings //

local ESP_Settings = {
    Enabled = false,
    LimitDistance = 2000,
    TeamCheck = false,
    TextSize = 13,
    Font = 2,

    Box = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Outline = true, Thickness = 1 },
    BoxFill = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.5 },
    Name = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    Distance = { Enabled = false, Color = Color3.fromRGB(200, 200, 200) },
    HealthBar = { Enabled = false },
    Tracer = { Enabled = false, Origin = "Bottom", Color = Color3.fromRGB(255, 255, 255) },
    Skeleton = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1 },

    Chams = { 
        Enabled = false, 
        FillColor = Color3.fromRGB(255, 0, 0), 
        OutlineColor = Color3.fromRGB(255, 255, 255),
        FillTransparency = 0.5,
        OutlineTransparency = 0
    }
}

-- // Aimbot Settings (Universal Aimbot Style) //

local AimbotSettings = {
    Enabled = false,
    TeamCheck = false,
    VisibleCheck = false,
    AimPart = "Head",
    FOV = 160,
    FOV_Color = Color3.fromRGB(255, 255, 255),  -- Weiß
    Smoothness = 10,
    Prediction = false,
    PredictionAmount = 0.142,
    MaximumDistance = 250,
    Strength = 5,
}

-- // ESP Cache //

local ESP_Cache = {}

-- // Drawing Functions //

local function NewDrawing(Type, Properties)
    local Obj = Drawing.new(Type)
    for k, v in pairs(Properties) do 
        pcall(function() Obj[k] = v end)
    end
    return Obj
end

-- // Create ESP //

local function CreateESP(Player)
    if Player == LocalPlayer then return end
    
    local Objects = {
        Box = NewDrawing("Square", {Thickness = 1, ZIndex = 2, Visible = false}),
        BoxOutline = NewDrawing("Square", {Thickness = 3, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        BoxFill = NewDrawing("Square", {Filled = true, ZIndex = 0, Visible = false}),
        Name = NewDrawing("Text", {Text = Player.Name, Center = true, Size = ESP_Settings.TextSize, Font = ESP_Settings.Font, Outline = true, ZIndex = 3, Visible = false}),
        Distance = NewDrawing("Text", {Center = true, Size = ESP_Settings.TextSize - 1, Font = ESP_Settings.Font, Outline = true, ZIndex = 3, Visible = false}),
        HealthBar = NewDrawing("Square", {Filled = true, ZIndex = 2, Visible = false}),
        HealthBarOutline = NewDrawing("Square", {Filled = true, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        Tracer = NewDrawing("Line", {Thickness = 1, ZIndex = 2, Visible = false}),
        TracerOutline = NewDrawing("Line", {Thickness = 3, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        SkeletonLines = {},
        Highlight = nil
    }

    for i = 1, 16 do
        table.insert(Objects.SkeletonLines, NewDrawing("Line", {Thickness = 1, ZIndex = 2, Visible = false}))
    end

    ESP_Cache[Player] = Objects
end

-- // Remove ESP //

local function RemoveESP(Player)
    if ESP_Cache[Player] then
        for k, v in pairs(ESP_Cache[Player]) do
            if k == "Highlight" and v then 
                pcall(function() v:Destroy() end)
            elseif k == "SkeletonLines" then
                for _, line in pairs(v) do 
                    pcall(function() line:Remove() end)
                end
            elseif v and v.Remove then 
                pcall(function() v:Remove() end)
            end
        end
        ESP_Cache[Player] = nil
    end
end

-- // Skeleton Connections //

local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

-- // ESP Render Loop //

RunService.RenderStepped:Connect(function()
    for Player, Objects in pairs(ESP_Cache) do
        if not Player or not Player.Character then continue end
        
        local Character = Player.Character
        local Humanoid = Character:FindFirstChild("Humanoid")
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        
        local IsValid = ESP_Settings.Enabled and Character and Humanoid and RootPart and Humanoid.Health > 0
        local IsTeammate = ESP_Settings.TeamCheck and Player.Team == LocalPlayer.Team
        
        if IsValid and not IsTeammate then
            local HRP_Pos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            local Dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and 
                        (LocalPlayer.Character.HumanoidRootPart.Position - RootPart.Position).Magnitude or 0

            -- // Chams //

            if ESP_Settings.Chams.Enabled then
                if not Objects.Highlight or Objects.Highlight.Parent ~= Character then
                    if Objects.Highlight then 
                        pcall(function() Objects.Highlight:Destroy() end)
                    end
                    local HL = Instance.new("Highlight")
                    HL.Parent = Character
                    HL.Adornee = Character
                    HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    Objects.Highlight = HL
                end
                local HL = Objects.Highlight
                HL.FillColor = ESP_Settings.Chams.FillColor
                HL.OutlineColor = ESP_Settings.Chams.OutlineColor
                HL.FillTransparency = ESP_Settings.Chams.FillTransparency
                HL.OutlineTransparency = ESP_Settings.Chams.OutlineTransparency
                HL.Enabled = true
            else
                if Objects.Highlight then 
                    pcall(function() Objects.Highlight:Destroy() end)
                    Objects.Highlight = nil 
                end
            end

            if OnScreen and Dist <= ESP_Settings.LimitDistance then
                local ScaleFactor = 1 / (HRP_Pos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
                local Width, Height = math.floor(4 * ScaleFactor), math.floor(6 * ScaleFactor)
                local BoxPos = Vector2.new(math.floor(HRP_Pos.X - Width * 0.5), math.floor(HRP_Pos.Y - Height * 0.5))

                -- // Box //

                if ESP_Settings.Box.Enabled then
                    Objects.Box.Size = Vector2.new(Width, Height)
                    Objects.Box.Position = BoxPos
                    Objects.Box.Color = ESP_Settings.Box.Color
                    Objects.Box.Thickness = ESP_Settings.Box.Thickness or 1
                    Objects.Box.Visible = true
                    Objects.BoxOutline.Size = Vector2.new(Width, Height)
                    Objects.BoxOutline.Position = BoxPos
                    Objects.BoxOutline.Visible = ESP_Settings.Box.Outline
                else
                    Objects.Box.Visible = false
                    Objects.BoxOutline.Visible = false
                end

                -- // Box Fill //

                if ESP_Settings.BoxFill.Enabled and ESP_Settings.Box.Enabled then
                    Objects.BoxFill.Size = Vector2.new(Width, Height)
                    Objects.BoxFill.Position = BoxPos
                    Objects.BoxFill.Color = ESP_Settings.BoxFill.Color
                    Objects.BoxFill.Transparency = ESP_Settings.BoxFill.Transparency
                    Objects.BoxFill.Visible = true
                else
                    Objects.BoxFill.Visible = false
                end

                -- // Name //

                if ESP_Settings.Name.Enabled then
                    Objects.Name.Position = Vector2.new(BoxPos.X + Width / 2, BoxPos.Y - Objects.Name.TextBounds.Y - 2)
                    Objects.Name.Color = ESP_Settings.Name.Color
                    Objects.Name.Visible = true
                else
                    Objects.Name.Visible = false
                end

                -- // Distance //

                if ESP_Settings.Distance.Enabled then
                    Objects.Distance.Text = math.floor(Dist) .. "m"
                    Objects.Distance.Position = Vector2.new(BoxPos.X + Width / 2, BoxPos.Y + Height + 2)
                    Objects.Distance.Color = ESP_Settings.Distance.Color
                    Objects.Distance.Visible = true
                else
                    Objects.Distance.Visible = false
                end

                -- // Health Bar //

                if ESP_Settings.HealthBar.Enabled then
                    local BarWidth = 2
                    local HealthY = Height * (Humanoid.Health / Humanoid.MaxHealth)
                    Objects.HealthBarOutline.Size = Vector2.new(BarWidth + 2, Height + 2)
                    Objects.HealthBarOutline.Position = Vector2.new(BoxPos.X - BarWidth - 6, BoxPos.Y - 1)
                    Objects.HealthBarOutline.Visible = true
                    Objects.HealthBar.Size = Vector2.new(BarWidth, HealthY)
                    Objects.HealthBar.Position = Vector2.new(BoxPos.X - BarWidth - 5, BoxPos.Y + (Height - HealthY))
                    Objects.HealthBar.Color = Color3.fromHSV((Humanoid.Health / Humanoid.MaxHealth) * 0.3, 1, 1)
                    Objects.HealthBar.Visible = true
                else
                    Objects.HealthBar.Visible = false
                    Objects.HealthBarOutline.Visible = false
                end

                -- // Tracer //

                if ESP_Settings.Tracer.Enabled then
                    local Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    if ESP_Settings.Tracer.Origin == "Center" then 
                        Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    elseif ESP_Settings.Tracer.Origin == "Mouse" then 
                        local M = UserInputService:GetMouseLocation() 
                        Origin = Vector2.new(M.X, M.Y) 
                    end
                    Objects.Tracer.From = Origin
                    Objects.Tracer.To = Vector2.new(HRP_Pos.X, HRP_Pos.Y)
                    Objects.Tracer.Color = ESP_Settings.Tracer.Color
                    Objects.Tracer.Visible = true
                    Objects.TracerOutline.From = Origin
                    Objects.TracerOutline.To = Vector2.new(HRP_Pos.X, HRP_Pos.Y)
                    Objects.TracerOutline.Visible = true
                else
                    Objects.Tracer.Visible = false
                    Objects.TracerOutline.Visible = false
                end

                -- // Skeleton //

                if ESP_Settings.Skeleton.Enabled then
                    local lineIndex = 1
                    for _, pair in ipairs(SkeletonConnections) do
                        local p1 = Character:FindFirstChild(pair[1])
                        local p2 = Character:FindFirstChild(pair[2])
                        
                        if p1 and p2 then
                            local pos1, onScreen1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, onScreen2 = Camera:WorldToViewportPoint(p2.Position)

                            if onScreen1 or onScreen2 then
                                local line = Objects.SkeletonLines[lineIndex]
                                if line then
                                    line.From = Vector2.new(pos1.X, pos1.Y)
                                    line.To = Vector2.new(pos2.X, pos2.Y)
                                    line.Color = ESP_Settings.Skeleton.Color
                                    line.Thickness = ESP_Settings.Skeleton.Thickness
                                    line.Visible = true
                                    lineIndex = lineIndex + 1
                                end
                            end
                        end
                    end
                    for i = lineIndex, #Objects.SkeletonLines do
                        Objects.SkeletonLines[i].Visible = false
                    end
                else
                    for _, line in pairs(Objects.SkeletonLines) do 
                        line.Visible = false 
                    end
                end

            else
                for k, v in pairs(Objects) do 
                    if k == "SkeletonLines" then 
                        for _, l in pairs(v) do l.Visible = false end
                    elseif typeof(v) ~= "Instance" and v.Visible ~= nil then 
                        v.Visible = false 
                    end
                end
            end
        else
            for k, v in pairs(Objects) do 
                if k == "SkeletonLines" then 
                    for _, l in pairs(v) do l.Visible = false end
                elseif typeof(v) ~= "Instance" and v.Visible ~= nil then 
                    v.Visible = false 
                end
            end
            if Objects.Highlight then 
                pcall(function() Objects.Highlight:Destroy() end)
                Objects.Highlight = nil 
            end
        end
    end
end)

-- // Player Events //

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, Plr in ipairs(Players:GetPlayers()) do 
    if Plr ~= LocalPlayer then 
        CreateESP(Plr) 
    end 
end

-- // FOV Circle (Drawing) - Immer am Mauszeiger //

local FOV = Drawing.new("Circle")
FOV.Visible = false
FOV.Transparency = 1
FOV.Color = AimbotSettings.FOV_Color
FOV.Thickness = 2.5
FOV.NumSides = 100
FOV.Radius = AimbotSettings.FOV
FOV.Filled = false

-- FOV Position am Mauszeiger halten
RunService.RenderStepped:Connect(function()
    FOV.Position = UserInputService:GetMouseLocation()
end)

-- // Get Target (Universal Aimbot Style) //

local function GetTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local closest = nil
    local bestDist = AimbotSettings.FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not plr.Character then continue end
        
        local Humanoid = plr.Character:FindFirstChild("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then continue end
        
        if AimbotSettings.TeamCheck and plr.Team == LocalPlayer.Team then continue end

        local part = plr.Character:FindFirstChild(AimbotSettings.AimPart) or plr.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local pos = part.Position
        if AimbotSettings.Prediction then
            pos = pos + (part.Velocity * AimbotSettings.PredictionAmount)
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
        if not onScreen then continue end

        -- Distanz zur MAUSPOSITION
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist >= bestDist then continue end

        -- Distanz-Check (max 250 Studs)
        local worldDist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                          (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude) or 0
        if worldDist > AimbotSettings.MaximumDistance then continue end

        if AimbotSettings.VisibleCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local result = Workspace:Raycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, rayParams)
            if result and not result.Instance:IsDescendantOf(plr.Character) then continue end
        end

        bestDist = dist
        closest = {
            Position = pos,
            ScreenPos = Vector2.new(screenPos.X, screenPos.Y),
            Player = plr
        }
    end
    return closest
end

-- // Aimbot Loop (Nur Q Toggle - KEIN Rechtsklick!) //

RunService.Heartbeat:Connect(function()
    -- FOV Updates
    FOV.Radius = AimbotSettings.FOV
    FOV.Visible = AimbotSettings.Enabled
    FOV.Color = AimbotSettings.FOV_Color

    -- NUR aimen wenn Aimbot an ist (KEIN Rechtsklick mehr!)
    if not AimbotSettings.Enabled then
        return
    end

    local target = GetTarget()
    if target then
        local mousePos = UserInputService:GetMouseLocation()
        local deltaX = (target.ScreenPos.X - mousePos.X) * (AimbotSettings.Strength / 100)
        local deltaY = (target.ScreenPos.Y - mousePos.Y) * (AimbotSettings.Strength / 100)
        
        local smoothFactor = 1 / (AimbotSettings.Smoothness or 10)
        deltaX = deltaX * smoothFactor
        deltaY = deltaY * smoothFactor
        
        local maxMove = 50
        deltaX = math.clamp(deltaX, -maxMove, maxMove)
        deltaY = math.clamp(deltaY, -maxMove, maxMove)
        
        if deltaX ~= 0 or deltaY ~= 0 then
            mousemoverel(deltaX, deltaY)
        end
    end
end)

-- // Q Toggle - Aimbot AN/AUS + Circle AN/AUS //

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        AimbotSettings.Enabled = not AimbotSettings.Enabled
        
        FOV.Visible = AimbotSettings.Enabled
        
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[Aimbot] " .. (AimbotSettings.Enabled and "🟢 AKTIVIERT" or "🔴 DEAKTIVIERT") .. " (Q)",
            Color = AimbotSettings.Enabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
        })
    end
end)

-- // UI //

Library:Watermark("GiG AIM) | V 2.0")
local Window = Library:Window("GiG AIM)")

-- // Visuals Tab //

local VisualsTab = Window:Tab("Visuals")
local EspPage = VisualsTab:SubTab("ESP")
local ChamsPage = VisualsTab:SubTab("Chams")

-- // ESP Main //

local MasterGroup = EspPage:Groupbox("Activation", "Left")
MasterGroup:AddToggle({
    Title = "Enable ESP",
    Default = false,
    Callback = function(V) 
        ESP_Settings.Enabled = V 
    end
})

-- // ESP Elements //

local ElementsGroup = EspPage:Groupbox("Elements", "Left")
ElementsGroup:AddToggle({ Title = "Boxes", Default = false, Callback = function(V) ESP_Settings.Box.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Skeleton", Default = false, Callback = function(V) ESP_Settings.Skeleton.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Names", Default = false, Callback = function(V) ESP_Settings.Name.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Health Bar", Default = false, Callback = function(V) ESP_Settings.HealthBar.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Distance", Default = false, Callback = function(V) ESP_Settings.Distance.Enabled = V end })
ElementsGroup:AddToggle({ Title = "Tracers", Default = false, Callback = function(V) ESP_Settings.Tracer.Enabled = V end })

-- // ESP Settings //

local EspSettingsGroup = EspPage:Groupbox("Settings", "Right")
EspSettingsGroup:AddColorPicker({ 
    Title = "Box Color", 
    Default = ESP_Settings.Box.Color, 
    Callback = function(V) ESP_Settings.Box.Color = V end 
})
EspSettingsGroup:AddColorPicker({ 
    Title = "Skeleton Color", 
    Default = ESP_Settings.Skeleton.Color, 
    Callback = function(V) ESP_Settings.Skeleton.Color = V end 
})
EspSettingsGroup:AddColorPicker({ 
    Title = "Name Color", 
    Default = ESP_Settings.Name.Color, 
    Callback = function(V) ESP_Settings.Name.Color = V end 
})
EspSettingsGroup:AddToggle({ 
    Title = "Box Fill", 
    Default = false, 
    Callback = function(V) ESP_Settings.BoxFill.Enabled = V end 
})
EspSettingsGroup:AddColorPicker({ 
    Title = "Fill Color", 
    Default = ESP_Settings.BoxFill.Color, 
    Callback = function(V) ESP_Settings.BoxFill.Color = V end 
})
EspSettingsGroup:AddSlider({ 
    Title = "Max Distance", 
    Min = 100, 
    Max = 5000, 
    Default = 2000, 
    Suffix = " studs", 
    Callback = function(V) ESP_Settings.LimitDistance = V end 
})

-- // Chams //

local ChamsGroup = ChamsPage:Groupbox("Chams", "Left")
ChamsGroup:AddToggle({ 
    Title = "Enable Chams", 
    Default = false, 
    Callback = function(V) ESP_Settings.Chams.Enabled = V end 
})
ChamsGroup:AddColorPicker({ 
    Title = "Fill Color", 
    Default = ESP_Settings.Chams.FillColor, 
    Callback = function(V) ESP_Settings.Chams.FillColor = V end 
})
ChamsGroup:AddColorPicker({ 
    Title = "Outline Color", 
    Default = ESP_Settings.Chams.OutlineColor, 
    Callback = function(V) ESP_Settings.Chams.OutlineColor = V end 
})

-- // Aimbot Tab //

local AimbotTab = Window:Tab("Aimbot")
local Page = AimbotTab:SubTab("Main")

-- // Aimbot Control //

Page:Groupbox("Aimbot Control", "Left"):AddToggle({
    Title = "Enable Aimbot (Q)",
    Default = false,
    Description = "Q toggelt Aimbot + Circle",
    Callback = function(v) 
        AimbotSettings.Enabled = v 
        FOV.Visible = v
    end
})

Page:Groupbox("Aimbot Control", "Left"):AddDropdown({
    Title = "Aim Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = "Head",
    Callback = function(v) AimbotSettings.AimPart = v end
})

-- // Aimbot Checks //

Page:Groupbox("Checks", "Left"):AddToggle({
    Title = "Visible Check (Wall Check)",
    Default = false,
    Callback = function(v) AimbotSettings.VisibleCheck = v end
})

Page:Groupbox("Checks", "Left"):AddToggle({
    Title = "Team Check",
    Default = false,
    Callback = function(v) AimbotSettings.TeamCheck = v end
})

-- // FOV Settings //

Page:Groupbox("FOV Settings", "Right"):AddSlider({
    Title = "FOV Size",
    Min = 10, Max = 600, Default = 160,
    Callback = function(v)
        AimbotSettings.FOV = v
    end
})

Page:Groupbox("FOV Settings", "Right"):AddColorPicker({
    Title = "FOV Color",
    Default = AimbotSettings.FOV_Color,
    Callback = function(v)
        AimbotSettings.FOV_Color = v
    end
})

-- // Aimbot Smoothness //

Page:Groupbox("Smoothness", "Left"):AddSlider({
    Title = "Smoothness",
    Min = 1, Max = 50, Default = 10,
    Suffix = " (lower = sharper)",
    Callback = function(v) AimbotSettings.Smoothness = v end
})

Page:Groupbox("Smoothness", "Left"):AddSlider({
    Title = "Strength",
    Min = 1, Max = 100, Default = 5,
    Suffix = "%",
    Callback = function(v) AimbotSettings.Strength = v end
})

-- // Distance Settings //

Page:Groupbox("Distance", "Left"):AddSlider({
    Title = "Max Distance",
    Min = 50, Max = 500, Default = 250,
    Suffix = " studs",
    Callback = function(v) AimbotSettings.MaximumDistance = v end
})

-- // Prediction //

Page:Groupbox("Prediction", "Left"):AddToggle({
    Title = "Enable Prediction",
    Default = false,
    Callback = function(v) AimbotSettings.Prediction = v end
})

Page:Groupbox("Prediction", "Left"):AddSlider({
    Title = "Prediction Amount",
    Min = 0.05, Max = 0.5, Default = 0.142,
    Suffix = " (lower = more accurate)",
    Callback = function(v) AimbotSettings.PredictionAmount = v end
})

-- // Settings Tab //

Window:Section("System")
local SettingsTab = Window:Tab("Settings")
local SettingsPage = SettingsTab:SubTab("Menu Settings")

-- // Config Manager //

local ConfigGroup = SettingsPage:Groupbox("Configuration", "Left")
local Configs = Library:GetConfigs()

ConfigGroup:AddDropdown({
    Title = "Select Config",
    Values = Configs,
    Default = "default",
    Multi = false,
    Flag = "SelectedConfig",
    Callback = function(Value) end
})

ConfigGroup:AddTextbox({
    Title = "New Config Name",
    Placeholder = "Type name...",
    Flag = "NewConfigName",
    Callback = function(Value) end
})

ConfigGroup:AddButton({
    Title = "Load Selected",
    Callback = function()
        local name = Library.Flags["SelectedConfig"]
        if name then
            Library:LoadConfig(name)
            Library:Notify("Success", "Config loaded: " .. name, 3)
        else
            Library:Notify("Error", "No config selected!", 3)
        end
    end
})

ConfigGroup:AddButton({
    Title = "Save Config",
    Callback = function()
        local name = Library.Flags["NewConfigName"]
        if name == "" or name == nil then name = Library.Flags["SelectedConfig"] end
        if name and name ~= "" then
            Library:SaveConfig(name)
            local NewList = Library:GetConfigs()
            if Library.Items["SelectedConfig"] then Library.Items["SelectedConfig"].Refresh(NewList) end
            Library:Notify("Success", "Config saved: " .. name, 3)
        else
            Library:Notify("Error", "Enter a name or select a config!", 3)
        end
    end
})

ConfigGroup:AddButton({
    Title = "Delete Config",
    Callback = function()
        local name = Library.Flags["SelectedConfig"]
        if name and name ~= "" then
            Library:DeleteConfig(name)
            local NewList = Library:GetConfigs()
            if Library.Items["SelectedConfig"] then 
                Library.Items["SelectedConfig"].Refresh(NewList) 
            end
            Library.Flags["SelectedConfig"] = nil
            Library:Notify("Success", "Config deleted: " .. name, 3)
        else
            Library:Notify("Error", "Select a config first!", 3)
        end
    end
})

ConfigGroup:AddButton({
    Title = "Refresh List",
    Callback = function()
        local NewList = Library:GetConfigs()
        if Library.Items["SelectedConfig"] then Library.Items["SelectedConfig"].Refresh(NewList) end
        Library:Notify("Configs", "List refreshed", 2)
    end
})

-- // Theme Manager //

local ThemeGroup = SettingsPage:Groupbox("Theme Manager", "Right")

local ThemeList = {}
if Library.ThemePresets then
    for ThemeName, _ in pairs(Library.ThemePresets) do
        table.insert(ThemeList, ThemeName)
    end
    table.sort(ThemeList)
    
    ThemeGroup:AddDropdown({
        Title = "Preset Theme",
        Values = ThemeList,
        Default = "Default",
        Multi = false,
        Callback = function(Value)
            if Library.SetTheme then
                Library:SetTheme(Value)
            else
                warn("Library is outdated, SetTheme missing!")
            end
        end
    })
    ThemeGroup:AddSeparator()
end

ThemeGroup:AddLabel("Custom Colors")

ThemeGroup:AddColorPicker({
    Title = "Accent Color", Default = Library.Theme.Accent, Flag = "ThemeAccent",
    Callback = function(Value) Library:UpdateTheme("Accent", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Background", Default = Library.Theme.Background, Flag = "ThemeBackground",
    Callback = function(Value) Library:UpdateTheme("Background", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Sidebar", Default = Library.Theme.Sidebar, Flag = "ThemeSidebar",
    Callback = function(Value) Library:UpdateTheme("Sidebar", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Groupbox", Default = Library.Theme.Groupbox, Flag = "ThemeGroupbox",
    Callback = function(Value) Library:UpdateTheme("Groupbox", Value) end
})

ThemeGroup:AddLabel("Text & Outlines")

ThemeGroup:AddColorPicker({
    Title = "Main Text", Default = Library.Theme.Text, Flag = "ThemeText",
    Callback = function(Value) Library:UpdateTheme("Text", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Secondary Text", Default = Library.Theme.TextDark, Flag = "ThemeTextDark",
    Callback = function(Value) Library:UpdateTheme("TextDark", Value) end
})

ThemeGroup:AddColorPicker({
    Title = "Outline/Stroke", Default = Library.Theme.Outline, Flag = "ThemeOutline",
    Callback = function(Value) Library:UpdateTheme("Outline", Value) end
})

ThemeGroup:AddButton({
    Title = "Reset Theme to Default",
    Callback = function()
        Library:SetTheme("Default")
        Library:Notify("Theme", "Colors reset to default", 2)
    end
})
    
-- // UI Settings //

local UISettings = SettingsPage:Groupbox("UI Settings", "Right")

UISettings:AddToggle({
    Title = "Show Watermark",
    Default = true,
    Flag = "WatermarkToggle",
    Callback = function(Value)
        Library.WatermarkSettings.Enabled = Value
    end
})

UISettings:AddTextbox({
    Title = "Watermark Text",
    Default = "GiG AIM V2",
    Placeholder = "Enter text...",
    ClearOnFocus = false,
    Callback = function(Value)
        Library.WatermarkSettings.Text = Value
    end
})

UISettings:AddButton({
    Title = "Unload / Destroy UI",
    Callback = function()
        FOV:Remove()
        Library:Destroy()
    end
})

print("GiG AIM) + Universal Aimbot loaded successfully!")
print("Q toggles Aimbot ON/OFF + Circle ON/OFF (NO RIGHT CLICK NEEDED!)")
