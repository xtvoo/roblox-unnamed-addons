--[[
    🎯 TARGET STRAFE (Callback Based) 🎯
    Uses api:add_desync_callback for native overrides.
]]

if not api then return warn("API Missing") end
api:set_lua_name("Target Strafe")
api:notify("TS: Callback Version Loaded", 5)

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Config
local Config = {
    Enabled = true,
    Radius = 12,
    Speed = 15,
    Height = 0
}

local State = {
    Angle = 0
}

-- UI
local Tab = api:GetTab("movement") or api:AddTab("movement")
local Box = Tab:AddLeftTabbox("Target Strafe")
local Main = Box:AddTab("Main")

Main:AddToggle("ts_enable", { Text = "Enable Strafe", Default = true, Callback = function(v) Config.Enabled = v end })
    :AddKeyPicker("ts_key", { Default = "Q", Mode = "Toggle", Text = "Active" })

Main:AddSlider("ts_rad", { Text = "Radius", Min = 5, Max = 40, Default = 12, Rounding = 0, Callback = function(v) Config.Radius = v end })
Main:AddSlider("ts_spd", { Text = "Speed", Min = 5, Max = 50, Default = 15, Rounding = 0, Callback = function(v) Config.Speed = v end })
Main:AddSlider("ts_hgt", { Text = "Height", Min = -10, Max = 10, Default = 0, Rounding = 1, Callback = function(v) Config.Height = v end })

local function GetTarget()
    -- 1. Try API "Silent Aim" target (Priority)
    if api.get_target then
        local t = api:get_target("silent")
        if t then return t end
        
        t = api:get_target("aimbot")
        if t then return t end
    end
    
    -- 2. Fallback: Closest to Mouse
    local mouse = LocalPlayer:GetMouse()
    local bestT, bestDist = nil, 400
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local root = p.Character.HumanoidRootPart
            local screen, vis = Workspace.CurrentCamera:WorldToViewportPoint(root.Position)
            if vis then
                local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screen.X, screen.Y)).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestT = p.Character
                end
            end
        end
    end
    return bestT
end


-- [ CALLBACK LOGIC ]
-- Priority 1 (highest/force)
if api.add_desync_callback then
    api:add_desync_callback(1, function()
        if not Config.Enabled then return nil end
        
        -- Check Keybind (Robust)
        local KeyActive = false
        if Options and Options.ts_key then
            KeyActive = Options.ts_key:GetState()
        elseif Toggles and Toggles.ts_key then
            KeyActive = Toggles.ts_key:GetState()
        else
            KeyActive = true -- Fallback
        end
        
        if not KeyActive then return nil end
        
        -- Check Target
        local TargetObj = GetTarget()
        if not TargetObj then return nil end
        
        -- Resolve Character (Head Priority)
        local Character = TargetObj
        if TargetObj:IsA("BasePart") then
            Character = TargetObj.Parent
        end
        
        if not Character then return nil end
        
        -- Prioritize Head for orbit center
        local TRoot = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")
        if not TRoot then return nil end
        
        -- Calculate Orbit Position matching current Angle
        local x = math.cos(State.Angle) * Config.Radius
        local z = math.sin(State.Angle) * Config.Radius
        local orbitPos = TRoot.Position + Vector3.new(x, Config.Height, z)
        
        -- Return valid CFrame (Look at Target)
        return CFrame.lookAt(orbitPos, TRoot.Position)
    end)
else
    warn("TS: api:add_desync_callback not found!")
end


-- [ STATE UPDATER ]
-- We still need a loop to update the Angle over time
api:add_connection(RunService.Heartbeat:Connect(function(dt)
    if not Config.Enabled then return end
    State.Angle = State.Angle + (Config.Speed * dt * 0.5)
end))
