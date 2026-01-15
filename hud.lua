api:set_lua_name("test_addon")

local Gui  -- declare at top, after you create it set Gui = that ScreenGui

api:on_event("unload", function()
    if Gui and Gui.Parent then
        pcall(function()
            Gui:Destroy()
        end)
    end

    api:notify("unloaded", 2)
end)


local Handler           = loadstring(game:HttpGet("https://raw.githubusercontent.com/xtvoo/roblox/refs/heads/main/handler"))()
local Workspace         = Handler:CloneRef("Workspace")
local Players           = Handler:CloneRef("Players")
local RunService        = Handler:CloneRef("RunService")
local ReplicatedStorage = Handler:CloneRef("ReplicatedStorage")
local TweenService      = Handler:CloneRef("TweenService")
local CoreGui           = Handler:CloneRef("CoreGui")

local LocalPlayer = Players.LocalPlayer
local MainEvent   = ReplicatedStorage.MainEvent

local Target              = nil
local KnockActive         = false
local BringActive         = false
local StompActive         = false
local CurrentTargetUserId = ""

local function Notify(text)
    api:notify(text)
end

-- Consolidated UI: visuals
local tab = api:GetTab("visuals") or api:AddTab("visuals")
local groupbox = tab:AddLeftGroupbox("HUD Settings")

groupbox:AddToggle("hud_visible", {
    Text = "Enable Silent Target HUD",
    Default = true,
    Callback = function(val)
        if Gui then Gui.Enabled = val end
    end
})


local function LocalReady()
    return LocalPlayer
       and LocalPlayer.Character
       and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
       and LocalPlayer.Character:FindFirstChild("Humanoid")
       and LocalPlayer.Character:FindFirstChild("Head")
       and LocalPlayer.Character:FindFirstChild("LowerTorso")
       and LocalPlayer.Character:FindFirstChild("BodyEffects")
       and LocalPlayer.Character.BodyEffects:FindFirstChild("Armor")
       and LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR")
end

local function TargetReady()
    return Target
       and Target.Character
       and Target.Character:FindFirstChild("HumanoidRootPart")
       and Target.Character:FindFirstChild("Humanoid")
end

local function GetStatus()
    if not Target then return nil end
    return api:get_status_cache(Target) -- K.O, SDeath, Grabbed, etc. [file:2]
end

--------------------------------------------------
-- ScreenGui + main window (bigger, no resize)
--------------------------------------------------

local Gui = Instance.new("ScreenGui")
Gui.Name         = "BetterTargetUI"
Gui.ResetOnSpawn = false
Gui.Parent       = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size                   = UDim2.new(0, 380, 0, 180)
MainFrame.Position               = UDim2.new(0.5, -190, 0.7, 0)
MainFrame.BackgroundColor3       = Color3.fromRGB(15, 15, 18)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel        = 0
MainFrame.Active                 = true
MainFrame.Draggable              = true
MainFrame.Parent                 = Gui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 14)
FrameCorner.Parent       = MainFrame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color           = Color3.fromRGB(90, 90, 255)
FrameStroke.Thickness       = 1.5
FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
FrameStroke.Transparency    = 0.15
FrameStroke.Parent          = MainFrame

--------------------------------------------------
-- Top bar with open/close
--------------------------------------------------

local TopBar = Instance.new("Frame")
TopBar.Size                   = UDim2.new(1, 0, 0, 26)
TopBar.BackgroundColor3       = Color3.fromRGB(10, 10, 14)
TopBar.BackgroundTransparency = 0.1
TopBar.BorderSizePixel        = 0
TopBar.Parent                 = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent       = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size                   = UDim2.new(1, -40, 1, 0)
TitleLabel.Position               = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text                  = "Silent Target"
TitleLabel.TextColor3            = Color3.fromRGB(220, 220, 255)
TitleLabel.Font                  = Enum.Font.GothamSemibold
TitleLabel.TextScaled            = true
TitleLabel.TextXAlignment        = Enum.TextXAlignment.Left
TitleLabel.Parent                = TopBar

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size                   = UDim2.new(0, 24, 0, 20)
ToggleButton.AnchorPoint            = Vector2.new(1, 0.5)
ToggleButton.Position               = UDim2.new(1, -8, 0.5, 0)
ToggleButton.BackgroundColor3       = Color3.fromRGB(35, 35, 50)
ToggleButton.BackgroundTransparency = 0.1
ToggleButton.BorderSizePixel        = 0
ToggleButton.Text                   = "-"
ToggleButton.TextColor3             = Color3.fromRGB(230, 230, 255)
ToggleButton.Font                   = Enum.Font.GothamBold
ToggleButton.TextSize               = 16
ToggleButton.Parent                 = TopBar

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent       = ToggleButton

local contentOpen   = true
local contentHeight = 180

local function SetOpenState(state)
    contentOpen = state
    if contentOpen then
        ToggleButton.Text = "-"
        MainFrame.Size    = UDim2.new(0, 380, 0, contentHeight)
    else
        ToggleButton.Text = "+"
        MainFrame.Size    = UDim2.new(0, 380, 0, 26)
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    SetOpenState(not contentOpen)
end)

--------------------------------------------------
-- Content area
--------------------------------------------------

local ContentHolder = Instance.new("Frame")
ContentHolder.Size                   = UDim2.new(1, 0, 1, -26)
ContentHolder.Position               = UDim2.new(0, 0, 0, 26)
ContentHolder.BackgroundTransparency = 1
ContentHolder.BorderSizePixel        = 0
ContentHolder.Name                   = "ContentHolder"
ContentHolder.Parent                 = MainFrame

-- thumbnail
local Thumbnail = Instance.new("ImageButton")
Thumbnail.Size                   = UDim2.new(0, 70, 0, 70)
Thumbnail.Position               = UDim2.new(0, 14, 0, 38)
Thumbnail.BackgroundColor3       = Color3.fromRGB(25, 25, 30)
Thumbnail.BackgroundTransparency = 0
Thumbnail.BorderSizePixel        = 0
Thumbnail.Image                  = ""
Thumbnail.Parent                 = ContentHolder

local ThumbCorner = Instance.new("UICorner")
ThumbCorner.CornerRadius = UDim.new(1, 0)
ThumbCorner.Parent       = Thumbnail

local ThumbStroke = Instance.new("UIStroke")
ThumbStroke.Color           = Color3.fromRGB(120, 120, 255)
ThumbStroke.Thickness       = 1.2
ThumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ThumbStroke.Parent          = Thumbnail

-- labels
local InfoFrame = Instance.new("Frame")
InfoFrame.Size                   = UDim2.new(1, -110, 0, 60)
InfoFrame.Position               = UDim2.new(0, 100, 0, 38)
InfoFrame.BackgroundTransparency = 1
InfoFrame.BorderSizePixel        = 0
InfoFrame.Parent                 = ContentHolder

local NameLabel = Instance.new("TextLabel")
NameLabel.Size                   = UDim2.new(1, 0, 0, 28)
NameLabel.Position               = UDim2.new(0, 0, 0, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.Text                   = "Name: -"
NameLabel.TextColor3             = Color3.fromRGB(240, 240, 255)
NameLabel.Font                   = Enum.Font.GothamSemibold
NameLabel.TextScaled             = true
NameLabel.TextXAlignment         = Enum.TextXAlignment.Left
NameLabel.Parent                 = InfoFrame

local IdLabel = Instance.new("TextLabel")
IdLabel.Size                   = UDim2.new(1, 0, 0, 24)
IdLabel.Position               = UDim2.new(0, 0, 0, 30)
IdLabel.BackgroundTransparency = 1
IdLabel.Text                   = "UserId: -"
IdLabel.TextColor3             = Color3.fromRGB(180, 180, 210)
IdLabel.Font                   = Enum.Font.Gotham
IdLabel.TextScaled             = true
IdLabel.TextXAlignment         = Enum.TextXAlignment.Left
IdLabel.Parent                 = InfoFrame

--------------------------------------------------
-- Knock / Bring / Stomp (same logic as before)
--------------------------------------------------

local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Size                   = UDim2.new(1, -24, 0, 28)
ButtonsFrame.Position               = UDim2.new(0, 12, 0, 120)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.BorderSizePixel        = 0
ButtonsFrame.Parent                 = ContentHolder

local function NewButton(text, offset)
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(0, 100, 0, 26)
    btn.Position               = UDim2.new(0, offset, 0, 1)
    btn.BackgroundColor3       = Color3.fromRGB(35, 35, 45)
    btn.BackgroundTransparency = 0.1
    btn.BorderSizePixel        = 0
    btn.TextColor3             = Color3.fromRGB(230, 230, 255)
    btn.Font                   = Enum.Font.GothamBold
    btn.TextSize               = 13
    btn.Text                   = text
    btn.Parent                 = ButtonsFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent       = btn

    local s = Instance.new("UIStroke")
    s.Color           = Color3.fromRGB(70, 70, 120)
    s.Thickness       = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(55, 55, 80)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        }):Play()
    end)

    return btn
end

local KnockButton = NewButton("KNOCK", 0)
local BringButton = NewButton("BRING", 110)
local StompButton = NewButton("STOMP", 220)

--------------------------------------------------
-- Drawer + extra options (whitelist + server wipe)
--------------------------------------------------

local DrawerButton = Instance.new("TextButton")
DrawerButton.Size                   = UDim2.new(0, 26, 0, 20)
DrawerButton.AnchorPoint            = Vector2.new(1, 1)
DrawerButton.Position               = UDim2.new(1, -8, 1, -8)
DrawerButton.BackgroundColor3       = Color3.fromRGB(40, 40, 60)
DrawerButton.BackgroundTransparency = 0.1
DrawerButton.BorderSizePixel        = 0
DrawerButton.Text                   = "⋮"
DrawerButton.TextColor3             = Color3.fromRGB(210, 210, 255)
DrawerButton.Font                   = Enum.Font.GothamBold
DrawerButton.TextSize               = 14
DrawerButton.Parent                 = ContentHolder

local DrawerCorner = Instance.new("UICorner")
DrawerCorner.CornerRadius = UDim.new(0, 6)
DrawerCorner.Parent       = DrawerButton

local ExtraFrame = Instance.new("Frame")
ExtraFrame.Size                   = UDim2.new(1, -24, 0, 26)
ExtraFrame.Position               = UDim2.new(0, 12, 1, -36)
ExtraFrame.BackgroundColor3       = Color3.fromRGB(20, 20, 30)
ExtraFrame.BackgroundTransparency = 0.15
ExtraFrame.BorderSizePixel        = 0
ExtraFrame.Visible                = false
ExtraFrame.Parent                 = ContentHolder

local ExtraCorner = Instance.new("UICorner")
ExtraCorner.CornerRadius = UDim.new(0, 8)
ExtraCorner.Parent       = ExtraFrame

local drawerOpen = false
DrawerButton.MouseButton1Click:Connect(function()
    drawerOpen = not drawerOpen
    ExtraFrame.Visible = drawerOpen
end)

local function NewSmallButton(text, offsetX)
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(0, 130, 0, 22)
    btn.Position               = UDim2.new(0, offsetX, 0, 2)
    btn.BackgroundColor3       = Color3.fromRGB(35, 35, 50)
    btn.BackgroundTransparency = 0.1
    btn.BorderSizePixel        = 0
    btn.Text                   = text
    btn.TextColor3             = Color3.fromRGB(220, 220, 255)
    btn.Font                   = Enum.Font.GothamBold
    btn.TextSize               = 12
    btn.Parent                 = ExtraFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent       = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(55, 55, 80)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        }):Play()
    end)

    return btn
end

local WhitelistButton  = NewSmallButton("Add to whitelist", 0)
local WipeToggleButton = NewSmallButton("Server wipe: OFF", 136)
local serverWipeOn     = false

local function UpdateWipeLabel()
    WipeToggleButton.Text = serverWipeOn and "Server wipe: ON" or "Server wipe: OFF"
end
UpdateWipeLabel()

--------------------------------------------------
-- Silent target sync + thumbnail
--------------------------------------------------

RunService.Heartbeat:Connect(function()
    if not LocalReady() then return end

    local cache = api:get_target_cache("silent") -- silent target cache. [file:2]
    local plr   = cache and cache.player or nil

    if plr ~= Target then
        Target = plr
        if Target then
            NameLabel.Text      = "Name: " .. Target.DisplayName
            IdLabel.Text        = "UserId: " .. Target.UserId
            CurrentTargetUserId = tostring(Target.UserId)
            Thumbnail.Image     = "https://www.roblox.com/headshot-thumbnail/image?userId="
                                  .. CurrentTargetUserId .. "&width=150&height=150&format=png" -- same format used in your HUD. [file:1]
        else
            NameLabel.Text      = "Name: -"
            IdLabel.Text        = "UserId: -"
            CurrentTargetUserId = ""
            Thumbnail.Image     = ""
        end
    end
end)

-- teleport on thumbnail
Handler:AddConnection("ThumbnailClick", Thumbnail.MouseButton1Click:Connect(function()
    if not LocalReady() then return end
    if CurrentTargetUserId == "" then return end
    if TargetReady() and Target.Character:FindFirstChild("UpperTorso") then
        if api and api.teleport then
            api:teleport(Target.Character.UpperTorso.CFrame + Vector3.new(0, 5, 0))
        end
    end
end))

--------------------------------------------------
-- Whitelist + server wipe logic
--------------------------------------------------

WhitelistButton.MouseButton1Click:Connect(function()
    if not Target then
        Notify("no silent target to whitelist")
        return
    end

    if Options and Options["ragebot_whitelist"] then
        local list = Options["ragebot_whitelist"].Value or {}
        if not table.find(list, Target.Name) then
            table.insert(list, Target.Name)
            Options["ragebot_whitelist"]:SetValue(list)
            Notify("added " .. Target.Name .. " to ragebot whitelist")
        else
            Notify(Target.Name .. " already in whitelist")
        end
    else
        Notify("ragebot whitelist flag not found")
    end
end)

WipeToggleButton.MouseButton1Click:Connect(function()
    serverWipeOn = not serverWipeOn
    UpdateWipeLabel()

    if Options and Options["ragebot_use_selected"] then
        Options["ragebot_use_selected"]:SetValue(not serverWipeOn)
        if serverWipeOn then
            Notify("server wipe enabled (ragebot_use_selected = false)")
        else
            Notify("server wipe disabled (ragebot_use_selected = true)")
        end
    else
        Notify("ragebot_use_selected flag not found")
    end
end)

--------------------------------------------------
-- Knock / Bring / Stomp (same behavior as earlier)
--------------------------------------------------

-- Knock: use ragebot until K.O
Handler:AddConnection("NewUI_Knock", KnockButton.MouseButton1Click:Connect(function()
    if not LocalReady() or not TargetReady() then return end

    local status = GetStatus()
    if status and status["K.O"] then
        Notify("already knocked")
        return
    end

    if KnockActive then
        KnockActive = false
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool") then
            Handler:Humanoid(LocalPlayer):UnequipTools()
        end
        api:get_ui_object("ragebot_keybind"):OverrideState(false)
        api:set_ragebot(nil)
        if Options and Options["ragebot_targets"] then
            Options["ragebot_targets"]:SetValue("nil")
        end
        return
    end

    KnockActive = true
    Notify("knocking " .. Target.Name)

    if Options and Options["ragebot_targets"] then
        Options["ragebot_targets"]:SetValue(Target.Name)
    end

    api:get_ui_object("ragebot_keybind"):OverrideState(true)
    api:set_ragebot(true)

    Handler:Disconnect("NewUI_KOCheck")
    Handler:AddConnection("NewUI_KOCheck", RunService.Heartbeat:Connect(function()
        if not KnockActive or not TargetReady() then
            Handler:Disconnect("NewUI_KOCheck")
            return
        end

        local s = GetStatus()
        if s and s["K.O"] then
            KnockActive = false
            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(nil)
            Notify("knocked " .. Target.Name)
            Handler:Disconnect("NewUI_KOCheck")
        end
    end))
end))

-- Bring: knock once if needed, then grab
Handler:AddConnection("NewUI_Bring", BringButton.MouseButton1Click:Connect(function()
    if not LocalReady() or not TargetReady() then return end

    if BringActive then
        BringActive = false
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool") then
            Handler:Humanoid(LocalPlayer):UnequipTools()
        end
        if Options and Options["ragebot_targets"] then
            Options["ragebot_targets"]:SetValue("nil")
        end
        api:get_ui_object("ragebot_keybind"):OverrideState(false)
        api:set_ragebot(nil)
        return
    end

    local status = GetStatus()

    if not (status and status["K.O"]) then
        if Options and Options["ragebot_targets"] then
            Options["ragebot_targets"]:SetValue(Target.Name)
        end
        Notify("knocking once " .. Target.Name)

        api:get_ui_object("ragebot_keybind"):OverrideState(true)
        api:set_ragebot(true)

        local start = tick()
        while tick() - start < 2 do
            task.wait()
            if not TargetReady() then break end
            local s = GetStatus()
            if s and s["K.O"] then
                Notify("knocked " .. Target.Name)
                break
            end
        end

        api:get_ui_object("ragebot_keybind"):OverrideState(false)
        api:set_ragebot(nil)

        status = GetStatus()
        if not (status and status["K.O"]) then
            Notify("failed to knock " .. Target.Name .. " (no K.O)")
            if Options and Options["ragebot_targets"] then
                Options["ragebot_targets"]:SetValue("nil")
            end
            return
        end
    end

    BringActive = true
    Notify("bringing " .. Target.Name)

    if Options and Options["ragebot_targets"] then
        Options["ragebot_targets"]:SetValue(Target.Name)
    end

    task.spawn(function()
        while BringActive and TargetReady() do
            local s = GetStatus()
            if not (s and s["K.O"]) then break end

            local char  = Target.Character
            local torso = char and char:FindFirstChild("UpperTorso")
            if not torso then break end

            if Options and Options["ragebot_stomp_offset"] then
                api:set_server_cframe(
                    CFrame.new(torso.Position) *
                    CFrame.new(0, Options["ragebot_stomp_offset"].Value, 0)
                )
            end

            if char:FindFirstChild("GRABBING_CONSTRAINT") then
                break
            end

            task.wait()
        end
    end)

    task.spawn(function()
        while BringActive and TargetReady() do
            local char = Target.Character
            local s    = GetStatus()
            if not (s and s["K.O"]) then break end
            if char:FindFirstChild("GRABBING_CONSTRAINT") then
                Notify("bringed " .. Target.Name)
                break
            end

            MainEvent:FireServer("Grabbing") -- same as original. [file:1]
            task.wait(0.4)
        end

        BringActive = false
        if Options and Options["ragebot_targets"] then
            Options["ragebot_targets"]:SetValue("nil")
        end
    end)
end))

-- Stomp: ragebot until SDeath
Handler:AddConnection("NewUI_Stomp", StompButton.MouseButton1Click:Connect(function()
    if not LocalReady() or not TargetReady() then return end

    if StompActive then
        StompActive = false
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool") then
            Handler:Humanoid(LocalPlayer):UnequipTools()
        end
        if Options and Options["ragebot_targets"] then
            Options["ragebot_targets"]:SetValue("nil")
        end
        api:get_ui_object("ragebot_keybind"):OverrideState(false)
        api:set_ragebot(nil)
        return
    end

    local status = GetStatus()
    if status and not status["SDeath"] then
        api:get_ui_object("ragebot_keybind"):OverrideState(true)
        api:set_ragebot(true)
    end

    if Options and Options["ragebot_targets"] then
        Options["ragebot_targets"]:SetValue(Target.Name)
    end

    StompActive = true

    Handler:Disconnect("NewUI_DeadCheck")
    Handler:AddConnection("NewUI_DeadCheck", RunService.Heartbeat:Connect(function()
        if not StompActive or not TargetReady() then
            Handler:Disconnect("NewUI_DeadCheck")
            return
        end

        local s = GetStatus()
        if s and s["SDeath"] then
            Notify("stomped " .. Target.Name)

            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool") then
                Handler:Humanoid(LocalPlayer):UnequipTools()
            end
            if Options and Options["ragebot_targets"] then
                Options["ragebot_targets"]:SetValue("nil")
            end
            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(nil)

            StompActive = false
            Handler:Disconnect("NewUI_DeadCheck")
        end
    end))
end))
