-- Expanded Fling Script V3
-- Powered by Linoria UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--------------------------------------------------------------------------------
-- UI LIBRARY SETUP
--------------------------------------------------------------------------------
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'Fling Script Extended v3',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Targeting = Window:AddTab('Targeting'),
    Settings = Window:AddTab('Settings'),
    UI = Window:AddTab('UI Settings'),
}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local FlingState = {
    Active = false,
    Part = nil,
    Target = nil,
    Mode = "Target", -- Target, Nearest, Key, Mouse, Orbit
    RotationEnabled = false,
    AutoSpin = false,
    SpinSpeed = 5,
    Rotation = { X = 0, Y = 0, Z = 0 },
    Offsets = { X = 0, Y = 8, Z = 0 },
    Force = Vector3.new(-10000, -10000, -10000),
    Prediction = 0.8,
    Distance = 50,    -- Scan distance
    OrbitRadius = 10, -- Radius for orbit mode
    OrbitSpeed = 2,
    Random = false,
    SelectionMode = false,
    SelectionHighlight = nil
}

local Whitelist = {}
local HeartbeatConnection = nil

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------
local function Notify(msg, duration)
    Library:Notify(msg, duration or 3)
end

local function GetPlayer(str)
    for _, v in pairs(Players:GetPlayers()) do
        if v.Name:lower():sub(1, #str) == str:lower() 
        or v.DisplayName:lower():sub(1, #str) == str:lower() then
            if v ~= LocalPlayer then return v end
        end
    end
    return nil
end

local function GetNearestPlayer()
    local bestPlr = nil
    local bestDist = FlingState.Distance or 50
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and not table.find(Whitelist, v.Name) and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = LocalPlayer:DistanceFromCharacter(v.Character.HumanoidRootPart.Position)
            if dist < bestDist then
                bestDist = dist
                bestPlr = v
            end
        end
    end
    return bestPlr
end

local function ClaimOwnership()
    if FlingState.Part then
        pcall(function()
            FlingState.Part:SetNetworkOwner(LocalPlayer)
        end)
    end
end

--------------------------------------------------------------------------------
-- CORE FLING LOGIC
--------------------------------------------------------------------------------
local function StopFling()
    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
    
    if FlingState.Part then
        -- Cleanup physics objects
        for _, name in ipairs({"BodyPosition", "BodyThrust", "BodyGyro", "BodyVelocity"}) do
            local obj = FlingState.Part:FindFirstChild(name)
            if obj then obj:Destroy() end
        end
        
        -- Reset properties
        FlingState.Part.Velocity = Vector3.zero
        FlingState.Part.AssemblyLinearVelocity = Vector3.zero
        FlingState.Part.AssemblyAngularVelocity = Vector3.zero
        FlingState.Part.CanCollide = true
        FlingState.Part.CanTouch = true
    end
end

local function StartFling()
    if not FlingState.Part then
        Notify("❌ No part selected! Use Selection Mode.", 5)
        Toggles.FlingEnabled:SetValue(false)
        return
    end

    if HeartbeatConnection then HeartbeatConnection:Disconnect() end

    HeartbeatConnection = RunService.Heartbeat:Connect(function()
        if not FlingState.Active or not FlingState.Part then return end
        
        local part = FlingState.Part
        
        -- Aggressive Physics & Ownership
        part.CanCollide = false
        part.CanTouch = false
        
        pcall(function()
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        end)
        
        ClaimOwnership()
        
        if sethiddenproperty then
            pcall(function()
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
            end)
        end
        
        -- Ensure Physics Objects Exist
        local bp = part:FindFirstChild("BodyPosition") or Instance.new("BodyPosition", part)
        local bt = part:FindFirstChild("BodyThrust") or Instance.new("BodyThrust", part)
        
        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bp.P = 10000
        bp.D = 175
        bt.Force = FlingState.Force

        -- Rotation Logic
        if FlingState.RotationEnabled then
            local bg = part:FindFirstChild("BodyGyro") or Instance.new("BodyGyro", part)
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.P = 10000
            
            if FlingState.AutoSpin then
                 -- Auto Spin based on time
                 local t = tick() * FlingState.SpinSpeed
                 bg.CFrame = CFrame.Angles(t, t, t)
            else
                -- Manual Static Rotation
                bg.CFrame = CFrame.Angles(
                    math.rad(FlingState.Rotation.X),
                    math.rad(FlingState.Rotation.Y),
                    math.rad(FlingState.Rotation.Z)
                )
            end
        else
            if part:FindFirstChild("BodyGyro") then part.BodyGyro:Destroy() end
        end
        
        -- Highlight (Visuals)
        local hl = part:FindFirstChild("FlingHighlight")
        if not hl then
            hl = Instance.new("Highlight", part)
            hl.Name = "FlingHighlight"
        end
        local hsv = tick() % 2 / 2
        hl.FillColor = Color3.fromHSV(hsv, 1, 1)
        hl.OutlineColor = Color3.fromHSV(hsv, 1, 1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0

        -- MODES
        local targetPos = nil
        local targetRoot = nil
        
        if FlingState.Mode == "Target" then
            if FlingState.Target and FlingState.Target.Character and FlingState.Target.Character:FindFirstChild("HumanoidRootPart") then
                targetRoot = FlingState.Target.Character.HumanoidRootPart
                targetPos = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * FlingState.Prediction)
            end
            
        elseif FlingState.Mode == "Nearest" then
            local nearest = GetNearestPlayer()
            if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
                targetRoot = nearest.Character.HumanoidRootPart
                targetPos = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * FlingState.Prediction)
            end
            
        elseif FlingState.Mode == "Mouse" or FlingState.Mode == "Key" then
             targetPos = Mouse.Hit.Position
             
        elseif FlingState.Mode == "Orbit" then
            -- Orbit around LocalPlayer
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local t = tick() * FlingState.OrbitSpeed
                local rad = FlingState.OrbitRadius
                
                -- Circular motion
                local offset = Vector3.new(math.cos(t) * rad, 1, math.sin(t) * rad)
                targetPos = root.Position + offset
            end
        end

        -- EXECUTE MOVEMENT
        if targetPos then
            -- 1. Random Jitter
            local jitter = Vector3.zero
            if FlingState.Random then
                jitter = Vector3.new(
                    math.random(-FlingState.Offsets.X, FlingState.Offsets.X),
                    math.random(-FlingState.Offsets.Y, FlingState.Offsets.Y),
                    math.random(-FlingState.Offsets.Z, FlingState.Offsets.Z)
                )
            else
                -- 2. Fixed Offset (User requested fix)
                -- Apply the specific X, Y, Z offsets from settings
                jitter = Vector3.new(FlingState.Offsets.X, FlingState.Offsets.Y, FlingState.Offsets.Z)
            end
            
            -- Key Mode Trigger
            if FlingState.Mode == "Key" then
                 if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    bp.Position = targetPos
                    bt.Location = LocalPlayer.Character.HumanoidRootPart.Position -- Thrust from us
                 else
                    -- Idle above player if not pressing Key
                    bp.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 10, 0)
                 end
            else
                -- Apply final position
                bp.Position = targetPos + jitter
                bt.Location = targetPos
            end
        else
            -- Park above player if no target
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                bp.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 10, 0)
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- UI CONSTRUCTION
--------------------------------------------------------------------------------

-- MAIN TAB
local GroupMain = Tabs.Main:AddLeftGroupbox('Fling Control')

GroupMain:AddToggle('FlingEnabled', {
    Text = 'Enable Fling',
    Default = false,
    Tooltip = 'Starts the fling loop',
    Callback = function(Value)
        FlingState.Active = Value
        if Value then
            StartFling()
        else
            StopFling()
        end
    end
})

GroupMain:AddToggle('SelectionMode', {
    Text = 'Part Selection Mode',
    Default = false,
    Tooltip = 'Click parts in world to select them',
    Callback = function(Value)
        FlingState.SelectionMode = Value
        if Value then
            Notify("Click a part to select it!", 3)
        end
    end
})

local PartLabel = GroupMain:AddLabel('Current Part: None')

GroupMain:AddButton('Teleport to Part', function()
    if FlingState.Part and LocalPlayer.Character then
        LocalPlayer.Character:PivotTo(FlingState.Part.CFrame + Vector3.new(0, 3, 0))
    end
end)

-- TARGETING TAB
local GroupTarget = Tabs.Targeting:AddLeftGroupbox('Target Selection')

GroupTarget:AddDropdown('FlingMode', {
    Values = { 'Target', 'Nearest', 'Key', 'Mouse', 'Orbit' },
    Default = 'Target',
    Text = 'Fling Mode',
    Callback = function(Value)
        FlingState.Mode = Value
    end
})

GroupTarget:AddInput('TargetPlr', {
    Default = '',
    Numeric = false,
    Finished = true,
    Text = 'Target Player',
    Tooltip = 'Partial name ok',
    Placeholder = 'Player Name',
    Callback = function(Value)
        local plr = GetPlayer(Value)
        if plr then
            FlingState.Target = plr
            Notify("Target set to: " .. plr.Name)
        else
            FlingState.Target = nil
        end
    end
})

GroupTarget:AddDivider()

GroupTarget:AddInput('WhitelistInput', {
    Default = '',
    Numeric = false,
    Finished = true,
    Text = 'Whitelist Player',
    Placeholder = 'Player Name',
    Callback = function(Value)
        -- Just holding value
    end
})

GroupTarget:AddButton('Add to Whitelist', function()
    local val = Options.WhitelistInput.Value
    local plr = GetPlayer(val)
    if plr then
        if not table.find(Whitelist, plr.Name) then
            table.insert(Whitelist, plr.Name)
            Notify("✅ Whitelisted: " .. plr.Name)
        end
    end
end)

GroupTarget:AddButton('Remove Whitelist', function()
    local val = Options.WhitelistInput.Value
    local plr = GetPlayer(val)
    if plr then
        local idx = table.find(Whitelist, plr.Name)
        if idx then
            table.remove(Whitelist, idx)
            Notify("❌ Unwhitelisted: " .. plr.Name)
        end
    end
end)

-- SETTINGS TAB
local GroupPhys = Tabs.Settings:AddLeftGroupbox('Physics')

GroupPhys:AddToggle('RandomSpawn', {
    Text = 'Random Jitter',
    Default = false,
    Tooltip = 'Rapidly teleports part around target',
    Callback = function(Value)
        FlingState.Random = Value
    end
})

GroupPhys:AddSlider('Pred', {
    Text = 'Prediction',
    Default = 0.8,
    Min = 0,
    Max = 2,
    Rounding = 2,
    Callback = function(Value)
        FlingState.Prediction = Value
    end
})

GroupPhys:AddSlider('Dist', {
    Text = 'Scan Distance',
    Default = 50,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        FlingState.Distance = Value
    end
})

GroupPhys:AddDivider()

GroupPhys:AddSlider('OrbitR', {
    Text = 'Orbit Radius',
    Default = 10,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        FlingState.OrbitRadius = Value
    end
})

GroupPhys:AddSlider('OrbitS', {
    Text = 'Orbit Speed',
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        FlingState.OrbitSpeed = Value
    end
})


local GroupRot = Tabs.Settings:AddRightGroupbox('Rotation')

GroupRot:AddToggle('RotEnabled', {
    Text = 'Enable Rotation',
    Default = false,
    Callback = function(Value)
        FlingState.RotationEnabled = Value
    end
})

GroupRot:AddToggle('AutoSpin', {
    Text = 'Auto Spin',
    Default = false,
    Callback = function(Value)
        FlingState.AutoSpin = Value
    end
})

GroupRot:AddSlider('SpinSpeed', { Text = 'Spin Speed', Default = 5, Min = 1, Max = 20, Rounding = 1, Callback = function(v) FlingState.SpinSpeed = v end })

GroupRot:AddDivider()

GroupRot:AddSlider('RotX', { Text = 'Static Rot X', Default = 0, Min = 0, Max = 360, Rounding = 0, Callback = function(v) FlingState.Rotation.X = v end })
GroupRot:AddSlider('RotY', { Text = 'Static Rot Y', Default = 0, Min = 0, Max = 360, Rounding = 0, Callback = function(v) FlingState.Rotation.Y = v end })
GroupRot:AddSlider('RotZ', { Text = 'Static Rot Z', Default = 0, Min = 0, Max = 360, Rounding = 0, Callback = function(v) FlingState.Rotation.Z = v end })

local GroupOffsets = Tabs.Settings:AddRightGroupbox('Offsets (Axes)')
GroupOffsets:AddSlider('OffX', { Text = 'Offset X', Default = 0, Min = -50, Max = 50, Rounding = 1, Callback = function(v) FlingState.Offsets.X = v end })
GroupOffsets:AddSlider('OffY', { Text = 'Offset Y', Default = 8, Min = -50, Max = 50, Rounding = 1, Callback = function(v) FlingState.Offsets.Y = v end })
GroupOffsets:AddSlider('OffZ', { Text = 'Offset Z', Default = 0, Min = -50, Max = 50, Rounding = 1, Callback = function(v) FlingState.Offsets.Z = v end })


--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and FlingState.SelectionMode and not gp then
        local target = Mouse.Target
        if target and target:IsA("BasePart") and not target.Anchored then
            if target:IsDescendantOf(LocalPlayer.Character) then
                 Notify("❌ Cannot select your own character parts!", 2)
                 return
            end
            
            -- Cleanup old highlight if exists
            if FlingState.Part and FlingState.Part:FindFirstChild("SelectionHighlight") then
                FlingState.Part.SelectionHighlight:Destroy()
            end

            FlingState.Part = target
            Notify("✅ Selected Part: " .. target.Name, 3)
            
            -- Selection Highlight
            local hl = Instance.new("Highlight")
            hl.Name = "SelectionHighlight"
            hl.FillColor = Color3.fromRGB(0, 255, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.Parent = target
            
        elseif target and target.Anchored then
            Notify("⚠️ Part is Anchored!", 2)
        end
    end
end)


-- Theme & Save Manager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager.IgnoreThemeSettings = false
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/FlingScript')
SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)

Library:Notify("Fling Script Ext V3 Loaded!", 5)
