--[[
Universal Aimbot v1.1.23 – Vollständig (950+ Zeilen), 250 Studs Max + Min 0
- Q toggelt Aimbot + FOV-Kreis (nur Ziele im Kreis + max 250 Studs)
- K toggelt AimAssist
- ESP permanent + togglebar im Hub
- Smoothness startet bei 5
- Kreis immer am Mauszeiger
- Hub lädt garantiert rechts oben
- MinAimDistance = 0 (zielst auf ALLE, auch nah dran)
]]

local VERSION = "v1.1.23 - Full + 250 Max Only"

if not getgenv().AimbotSettings then
    getgenv().AimbotSettings = {
        TeamCheck = true,
        VisibleCheck = true,
        IgnoreTransparency = true,
        IgnoredTransparency = 0.5,
        RefreshRate = 10,
        Keybind = "MouseButton2",
        ToggleKey = "RightShift",
        MaximumDistance = 250,          -- Obergrenze 250 Studs
        MinAimDistance = 0,             -- 0 = zielst auf ALLE (kein Nahbereich-Ignore)
        AlwaysActive = false,
        Aimbot = {
            Enabled = false,
            TargetPart = "Head",
            Use_mousemoverel = true,
            Strength = 5,               -- Startwert 5
            AimType = "Toggle",
            AimAtNearestPart = false
        },
        AimAssist = {
            Enabled = false,
            MinFov = 15,
            MaxFov = 80,
            DynamicFov = true,
            ShowFov = false,
            Strength = 55,
            SlowSensitivity = true,
            SlowFactor = 1.75,
            RequireMovement = true
        },
        FovCircle = {
            Enabled = true,
            Dynamic = true,
            Radius = 120,
            Transparency = 0.7,
            Color = Color3.fromRGB(255,255,255),
            NumSides = 100,
        },
        TriggerBot = {
            Enabled = false,
            Delay = 60,
            Spam = true,
            ClicksPerSecond = 10,
            UseKeybind = false,
        },
        Crosshair = {
            Enabled = false,
            Transparency = 1,
            TransparencyKeybind = 1,
            Color = Color3.fromRGB(255, 0, 0),
            RainbowColor = false,
            Length = 15,
            Thickness = 2,
            Offset = 0
        },
        Prediction = {
            Enabled = false,
            Strength = 2
        },
        Priority = {},
        Whitelisted = {},
        WhitelistFriends = true,
        Ignore = {}
    }
end

if not AimbotSettings.IgnoredTransparency then
    local bind = Instance.new("BindableFunction")
    bind.OnInvoke = function()
        setclipboard("https://pastebin.com/raw/nwqE7v07")
    end
    game:GetService("StarterGui"):SetCore("SendNotification",{
        Title = "Universal Aimbot",
        Text = "Please update your script!",
        Duration = 5,
        Button1 = "Get Latest Script",
        Callback = bind
    })
    return
end

local players = game:GetService("Players")
local player = players.LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local mousemoverel = mousemoverel
local mouse1press = mouse1press or mouse1down
local mouse1release = mouse1release or mouse1up
local Drawingnew = Drawing.new
local Fonts = Drawing.Fonts
local tableinsert = table.insert
local WorldToViewportPoint = camera.WorldToViewportPoint
local CFramenew = CFrame.new
local Vector2new = Vector2.new
local fromRGB = Color3.fromRGB
local fromHSV = Color3.fromHSV
local mathfloor = math.floor
local mathclamp = math.clamp
local mathhuge = math.huge
local lower = string.lower
local mouse = uis:GetMouseLocation()
local osclock = os.clock
local RaycastParamsnew = RaycastParams.new
local taskwait = task.wait
local taskspawn = task.spawn
local GameId = game.GameId
local ss = getgenv().AimbotSettings
local Aimbot = ss.Aimbot
local AimAssist = ss.AimAssist
local FovCircle = ss.FovCircle
local Trigger = ss.TriggerBot
local Mouse = player:GetMouse()

-- ESP
local esp_active = true

local function addESP(character)
    if character:FindFirstChild("ESPBox") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPBox"
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = esp_active
    highlight.Adornee = character
    highlight.Parent = character
end

for _, other in pairs(players:GetPlayers()) do
    if other ~= player then
        if other.Character then addESP(other.Character) end
        other.CharacterAdded:Connect(addESP)
    end
end

players.PlayerAdded:Connect(function(other)
    other.CharacterAdded:Connect(addESP)
end)

-- Game-spezifische Ignore
if GameId == (111958650 or 115797356 or 147332621) then
    ss.Ignore = {workspace.Ray_Ignore}
elseif GameId == 833423526 then
    ss.Ignore = {workspace.IgnoreThese}
elseif GameId == 1168263273 then
    do end
elseif GameId == 2162282815 then
    ss.Ignore = {camera, player.Character, workspace.RaycastIgnore, workspace.DroppedWeapons, workspace.MapFolder.Map.Ramps, workspace.MapFolder.Map.Walls.MapWalls}
elseif workspace:FindFirstChild("Ignore") then
    tableinsert(ss.Ignore, workspace.Ignore)
elseif workspace:FindFirstChild("RaycastIgnore") then
    tableinsert(ss.Ignore, workspace.RaycastIgnore)
end

if UAIM then
    UAIM:Destroy()
end

local bodyparts = {
"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot",
"Torso","Left Arm","Right Arm","Left Leg","Right Leg",
"Chest","Hips","LeftArm","LeftForearm","RightArm","RightForearm","LeftLeg","LeftForeleg","RightLeg","RightForeleg"
}

local ads = false
local aimassist_active = false
local olddelta = uis.MouseDeltaSensitivity
local triggering = false
local mousedown = false
local Ignore = {camera}

local gids = {
['arsenal'] = 111958650,
['pf'] = 113491250,
['pft'] = 115272207,
['pfu'] = 1256867479,
['bb'] = 1168263273,
['rp'] = 2162282815,
['mm2'] = 66654135
}

local getEntry, raycast, ts, characters, teams, rp

if (GameId == gids.pf) or (GameId == gids.pft) or (GameId == gids.pfu) then
    local require = rawget(getrenv().shared, "require")
    if require == nil then
        setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/Spoorloos/scripts/main/pf-actor-bypass.lua"))()')
        local a = Instance.new("Message", game.CoreGui)
        a.Text = "-- Universal Aimbot Notice --\n\nA script has been copied to your clipboard.\nPlease put this script in your exploit's autoexec folder and rejoin the game.\n(this script is required to bypass the new update)\n\nbypass was created by Spoorloos"
        return
    end
    local _cache = rawget(debug.getupvalue(require, 1), "_cache")
    local ReplicationInterface = rawget(rawget(_cache, "ReplicationInterface"), "module")
    getEntry = rawget(ReplicationInterface, "getEntry")
elseif GameId == gids.bb then
    for _,v in next, getgc(true) do
        if typeof(v) == "table" and rawget(v, "InitProjectile") and rawget(v, "TS") then
            ts = rawget(v, "TS")
            characters = ts.Characters
            teams = ts.Teams
        end
    end
elseif GameId == gids.rp then
    rp = true
end

local rootpart = (getchar and "Torso") or (ts and "Chest") or "HumanoidRootPart"

local setidentity = setidentity or setthreadidentity or set_thread_identity or setthreadcontext or set_thread_context or (syn and syn.set_thread_identity) or nil

function safecall(func, env, ...)
    if not setidentity then
        return func(...)
    end
    local suc, env = pcall(getsenv, env)
    return coroutine.wrap(function(...)
        setidentity(2)
        if suc then
            setfenv(0, env)
            setfenv(1, env)
        end
        return func(...)
    end)(...)
end

local oldfuncs = {}

function IsAlive(plr)
    local char = plr.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return char
    end
    return false
end

function GetChar(plr)
    return plr.Character
end

function GetTeam(plr)
    return plr.Team
end

function IsFFA()
    local t = {}
    for _,v in next, players:GetPlayers() do
        local team = GetTeam(v)
        if team == nil then
            return true
        end
        team = team.Name or team
        if t[team] then
            return true
        else
            tableinsert(t, team)
        end
    end
    return #t == 1
end

function ClosestPlayer()
    mouse = uis:GetMouseLocation()
    local plr = nil
    local closest = math.huge
    local myteam = GetTeam(player)
    for _,v in next, ss.Priority do
        v = players:FindFirstChild(v)
        if v and IsAlive(v) and InFov(v) then
            return v
        end
    end
    for _,v in next, players:GetPlayers() do
        if v ~= player then
            local char = GetChar(v)
            if char ~= nil then
                local cf = char:GetPivot()
                local vector, inViewport = WorldToViewportPoint(camera, cf.Position)
                if inViewport then
                    local mag = (Vector2new(mouse.X, mouse.Y) - Vector2new(vector.X, vector.Y)).Magnitude
                    local team = GetTeam(v)
                    if mag < closest and ((team ~= nil and team ~= myteam) or team == nil or not ss.TeamCheck) then
                        plr = v
                        closest = mag
                    end
                end
            end
        end
    end
    return plr
end

local params = RaycastParamsnew()
params.FilterType = Enum.RaycastFilterType.Blacklist
params.IgnoreWater = true

function IsVisible(plr, character, mycharacter, cf, targetpos, valid)
    local char = character or GetChar(plr)
    if ss.VisibleCheck and (valid or IsAlive(plr) and char:FindFirstChild(Aimbot.TargetPart)) then
        local mychar = mycharacter or GetChar(player)
        tableinsert(Ignore, mychar)
        params.FilterDescendantsInstances = Ignore
        local cf = cf or camera.CFrame.Position
        local targetpos = targetpos or char[Aimbot.TargetPart].Position
        local result = workspace:Raycast(cf, (targetpos - cf).Unit * 500, params)
        if result then
            local ins = result.Instance
            local isdes = ins:IsDescendantOf(char)
            local model = ins:FindFirstAncestorOfClass("Model")
            if ss.IgnoreTransparency then
                if ins.Transparency > ss.IgnoredTransparency and not (model ~= nil and model:FindFirstChildOfClass("Humanoid")) and not isdes then
                    tableinsert(Ignore, ins)
                    return IsVisible(plr, char, mychar, cf, targetpos, true)
                elseif isdes then
                    return true
                end
            elseif isdes then
                return true
            end
        end
    elseif not ss.VisibleCheck and IsAlive(plr) then
        return true
    end
    return false
end

task.spawn(function()
    while true do
        if ss ~= nil and typeof(ss.Ignore) == "table" then
            for _,v in next, ss.Ignore do
                tableinsert(Ignore, v)
            end
        end
        taskwait(3)
    end
end)

local fov

function InFov(plr,Fov)
    mouse = uis:GetMouseLocation()
    if IsAlive(plr) then
        local char = GetChar(plr)
        if ts and char:FindFirstChild("Body") then
            char = char.Body
        end
        local target = char:FindFirstChild(Aimbot.TargetPart)
        if target then
            local _, inViewport = WorldToViewportPoint(camera, target.Position)
            if (FovCircle.Enabled or AimAssist.Enabled) and inViewport then
                for _,v in next, char:GetChildren() do
                    if table.find(bodyparts, v.Name) and v.ClassName:find("Part") then
                        local vector2, inViewport2 = WorldToViewportPoint(camera, v.Position)
                        if inViewport2 and (Vector2new(mouse.X, mouse.Y) - Vector2new(vector2.X, vector2.Y)).Magnitude <= (Fov or fov.Radius or FovCircle.Radius) then
                            return true
                        end
                    end
                end
            elseif not FovCircle.Enabled and IsAlive(plr) then
                return true
            end
        else
            return false
        end
    end
    return false
end

do
    if getEntry then
        local playercache = {}
        local function GetPlayerObject(plr)
            local cached = playercache[plr]
            if cached then return cached end
            local obj = getEntry(plr)
            playercache[plr] = obj
            return obj
        end
        GetChar = function(plr)
            if plr == player then return nil end
            local obj = GetPlayerObject(plr)
            if obj ~= nil then
                local thirdPersonObject = obj._thirdPersonObject
                if thirdPersonObject then
                    return thirdPersonObject:getCharacterHash().head.Parent
                end
            end
            return nil
        end
        IsAlive = GetChar
    end
    if ts then
        hookfunction(PluginManager, error)
        GetChar = function(plr)
            return characters:GetCharacter(plr)
        end
        IsAlive = GetChar
        GetTeam = function(plr)
            return teams:GetPlayerTeam(plr, plr)
        end
    end
    if GameId == gids.arsenal then
        local ffa = game:GetService("ReplicatedStorage"):WaitForChild("wkspc"):WaitForChild("FFA")
        IsFFA = function()
            return ffa.Value
        end
    end
    if rp then
        local mapfolder = workspace:WaitForChild("MapFolder")
        local playerfolder = mapfolder:WaitForChild("Players")
        local gamestats = mapfolder:WaitForChild("GameStats")
        GetChar = function(plr)
            return playerfolder:FindFirstChild(plr.Name)
        end
        IsAlive = GetChar
        GetTeam = function(plr)
            local char = GetChar(plr) if not char then return "" end
            local team = char:FindFirstChild("Team") if not team then return "" end
            return team.Value
        end
        IsFFA = function()
            return gamestats.GameMode.Value == "Deathmatch"
        end
    end
    if GameId == gids.mm2 then
        local sheriff = nil
        local murderer = nil
        GetTeam = function(plr)
            local backpack = plr.Backpack
            local char = GetChar(plr)
            if (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
                sheriff = plr
                return "Sheriff"
            elseif (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
                murderer = plr
                return "Murderer"
            end
            return sheriff == player and "Sheriff" or "Innocent"
        end
    end
end

oldfuncs.alive = IsAlive
oldfuncs.character = GetChar
oldfuncs.team = GetTeam
oldfuncs.ffa = IsFFA
oldfuncs.closest = ClosestPlayer
oldfuncs.visible = IsVisible
oldfuncs.fov = InFov

function IsWhitelisted(plr)
    if table.find(ss.Whitelisted, (plr.Name or plr.UserId)) then
        return true
    end
    return false
end

local uit = Enum.UserInputType
local kc = Enum.KeyCode
local mb1 = uit.MouseButton1

-- INPUT-HANDLING: Q → Aimbot, K → AimAssist
local conn1 = uis.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Q then
        ads = not ads
        Aimbot.Enabled = ads
        fov.Visible = ads and FovCircle.Enabled or false
        
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[Aimbot] " .. (ads and "aktiviert" or "deaktiviert") .. " (Q)",
            Color = ads and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
        })
    end
    if i.KeyCode == Enum.KeyCode.K then
        aimassist_active = not aimassist_active
        AimAssist.Enabled = aimassist_active
        
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[AimAssist] " .. (aimassist_active and "aktiviert" or "deaktiviert") .. " (K)",
            Color = aimassist_active and Color3.fromRGB(100,200,255) or Color3.fromRGB(200,150,255)
        })
    end
    if i.UserInputType == mb1 then
        mousedown = true
    end
end)

local conn2 = uis.InputEnded:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == mb1 then
        mousedown = false
    end
end)

fov = Drawingnew("Circle")
fov.Visible = false
fov.Transparency = 1
fov.Color = fromRGB(255,255,255)
fov.Thickness = 2
fov.NumSides = 100
fov.Radius = FovCircle.Radius
fov.Filled = false

-- Kreis immer am Mauszeiger
RunService.RenderStepped:Connect(function()
    fov.Position = uis:GetMouseLocation()
end)

-- Moderner Hub – garantiert laden
local gui = Instance.new("ScreenGui")
gui.Name = "AimbotHubFixed"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.IgnoreGuiInset = true
gui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 320)
mainFrame.Position = UDim2.new(1, -280, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 16)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(60, 60, 90)
uiStroke.Thickness = 1.5
uiStroke.Transparency = 0.5
uiStroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Aimbot Hub"
titleText.TextColor3 = Color3.fromRGB(220, 220, 255)
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 20
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 34)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -55)
content.Position = UDim2.new(0, 10, 0, 45)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- ESP Toggle
local espToggleBtn = Instance.new("TextButton")
espToggleBtn.Size = UDim2.new(1, 0, 0, 45)
espToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
espToggleBtn.Text = "ESP: " .. (esp_active and "AN" or "AUS")
espToggleBtn.TextColor3 = esp_active and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 140, 140)
espToggleBtn.Font = Enum.Font.GothamSemibold
espToggleBtn.TextSize = 16
espToggleBtn.Parent = content

local espBtnCorner = Instance.new("UICorner")
espBtnCorner.CornerRadius = UDim.new(0, 10)
espBtnCorner.Parent = espToggleBtn

espToggleBtn.MouseButton1Click:Connect(function()
    esp_active = not esp_active
    espToggleBtn.Text = "ESP: " .. (esp_active and "AN" or "AUS")
    espToggleBtn.TextColor3 = esp_active and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 140, 140)
    
    for _, other in pairs(players:GetPlayers()) do
        if other ~= player and other.Character then
            local hl = other.Character:FindFirstChild("ESPBox")
            if hl then hl.Enabled = esp_active end
        end
    end
end)

-- Smoothness Slider
local smoothLabel = Instance.new("TextLabel")
smoothLabel.Size = UDim2.new(1, 0, 0, 25)
smoothLabel.Position = UDim2.new(0, 0, 0, 60)
smoothLabel.BackgroundTransparency = 1
smoothLabel.Text = "Smoothness: " .. Aimbot.Strength
smoothLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
smoothLabel.Font = Enum.Font.Gotham
smoothLabel.TextSize = 15
smoothLabel.Parent = content

local smoothSlider = Instance.new("Frame")
smoothSlider.Size = UDim2.new(1, 0, 0, 12)
smoothSlider.Position = UDim2.new(0, 0, 0, 90)
smoothSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
smoothSlider.Parent = content

local smoothFill = Instance.new("Frame")
smoothFill.Size = UDim2.new(Aimbot.Strength / 200, 0, 1, 0)
smoothFill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
smoothFill.Parent = smoothSlider

local smoothCorner = Instance.new("UICorner")
smoothCorner.CornerRadius = UDim.new(1, 0)
smoothCorner.Parent = smoothSlider
smoothCorner:Clone().Parent = smoothFill

local smoothDragging = false
smoothSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        smoothDragging = true
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        smoothDragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if smoothDragging then
        local mousePos = uis:GetMouseLocation()
        local relX = math.clamp((mousePos.X - smoothSlider.AbsolutePosition.X) / smoothSlider.AbsoluteSize.X, 0, 1)
        local newVal = math.floor(relX * 200)
        Aimbot.Strength = newVal
        smoothFill.Size = UDim2.new(relX, 0, 1, 0)
        smoothLabel.Text = "Smoothness: " .. newVal
    end
end)

-- Radius Slider
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(1, 0, 0, 25)
radiusLabel.Position = UDim2.new(0, 0, 0, 120)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Kreis Radius: " .. FovCircle.Radius
radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.TextSize = 15
radiusLabel.Parent = content

local radiusSlider = Instance.new("Frame")
radiusSlider.Size = UDim2.new(1, 0, 0, 12)
radiusSlider.Position = UDim2.new(0, 0, 0, 150)
radiusSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
radiusSlider.Parent = content

local radiusFill = Instance.new("Frame")
radiusFill.Size = UDim2.new(FovCircle.Radius / 400, 0, 1, 0)
radiusFill.BackgroundColor3 = Color3.fromRGB(255, 140, 80)
radiusFill.Parent = radiusSlider

local radiusCorner = Instance.new("UICorner")
radiusCorner.CornerRadius = UDim.new(1, 0)
radiusCorner.Parent = radiusSlider
radiusCorner:Clone().Parent = radiusFill

local radiusDragging = false
radiusSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radiusDragging = true
    end
end)

RunService.RenderStepped:Connect(function()
    if radiusDragging then
        local mousePos = uis:GetMouseLocation()
        local relX = math.clamp((mousePos.X - radiusSlider.AbsolutePosition.X) / radiusSlider.AbsoluteSize.X, 0, 1)
        local newRadius = math.floor(relX * 350 + 50)
        FovCircle.Radius = newRadius
        radiusFill.Size = UDim2.new((newRadius - 50) / 350, 0, 1, 0)
        radiusLabel.Text = "Kreis Radius: " .. newRadius
        fov.Radius = newRadius
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        radiusDragging = false
    end
end)

-- Update Kreis Position
RunService.RenderStepped:Connect(function()
    fov.Position = uis:GetMouseLocation()
end)

-- Aimbot + AimAssist mit 250 Max + Min 0
RunService.Heartbeat:Connect(function()
    fov.Position = uis:GetMouseLocation()
    fov.Radius = FovCircle.Radius
    fov.Visible = Aimbot.Enabled

    if Aimbot.Enabled then
        local target = ClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(Aimbot.TargetPart) and InFov(target) then
            local part = target.Character[Aimbot.TargetPart]
            local dist = (part.Position - camera.CFrame.Position).Magnitude
            
            -- Nur aimen, wenn max 250 Studs (Min 0 = alle Entfernungen erlaubt)
            if dist <= ss.MaximumDistance then
                local screen = WorldToViewportPoint(camera, part.Position)
                local mousePos = uis:GetMouseLocation()
                local deltaX = (screen.X - mousePos.X) * (Aimbot.Strength / 100)
                local deltaY = (screen.Y - mousePos.Y) * (Aimbot.Strength / 100)
                mousemoverel(deltaX, deltaY)
            end
        end
    end

    if AimAssist.Enabled then
        uis.MouseDeltaSensitivity = olddelta * 0.6
    else
        uis.MouseDeltaSensitivity = olddelta
    end
end)

-- Willkommensnachricht
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "[Aimbot] Vollständig geladen – Aimbot nur bis 250 Studs, Min 0 (zielst auf ALLE im Kreis), Smoothness startet bei 5",
    Color = Color3.fromRGB(180, 255, 180)
})

print("[Aimbot] Script vollständig geladen – Q toggelt, Aim nur bis 250 Studs, alle nahen Ziele erlaubt")

getgenv().UAIM = aimbot
return aimbot
