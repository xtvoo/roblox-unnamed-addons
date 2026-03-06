--[[
    Unnamed Addon: Grenade Teleport V2
    Based on RPG script pattern - continuous scanning, no anchoring
]]

api:set_lua_name("GrenadeTP_V2")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Settings
local Settings = {
    Enabled = false,
    Duration = 3.0,
    Offset = Vector3.new(0, 1, 0),
}

-- UI Setup
local tabs = { Combat = api:GetTab("combat") or api:AddTab("combat") }
local sec = tabs.Combat:AddRightGroupbox("Grenade TP V2")

sec:AddToggle("GTP2_Enable", { 
    Text = "Enable Grenade TP", 
    Default = false,
    Callback = function(val) Settings.Enabled = val end
})

local OffsetSlider = sec:AddSlider("GTP2_Offset", { 
    Text = "Height Offset", 
    Default = 1, 
    Min = 0, 
    Max = 5, 
    Rounding = 1,
    Suffix = " studs",
    Callback = function(val) Settings.Offset = Vector3.new(0, val, 0) end
})

local BuyAmount = sec:AddSlider("GTP2_Amount", { 
    Text = "Buy Amount", 
    Default = 1, 
    Min = 1, 
    Max = 10, 
    Rounding = 0 
})

sec:AddDivider()

-- Helper Functions
local function resolve_upper_root(plr)
    local char = plr.Character
    if not char then return nil, nil end
    
    local upper = char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
    
    return char, upper
end

local function GetTarget()
    -- Try global silent aim target first
    if _G.SilentAimTarget and _G.SilentAimTarget.Character then
        local _, root = resolve_upper_root(_G.SilentAimTarget)
        if root then
            return _G.SilentAimTarget
        end
    end
    
    -- Fallback: use api:get_target
    local target = api:get_target("silent")
    if target then
        local _, root = resolve_upper_root(target)
        if root then
            return target
        end
    end
    
    return nil
end

-- Grenade tracking (same as RPG script)
local grenadeTimers = {}
local processedCount = 0

-- Main grenade teleport function (RPG pattern - called every Heartbeat)
local function TeleportGrenades()
    if not Settings.Enabled then return end
    
    local target = GetTarget()
    if not target then return end
    
    local _, targetRoot = resolve_upper_root(target)
    if not targetRoot then return end
    
    local target_pos = targetRoot.Position + Settings.Offset
    
    -- Scan ALL unanchored parts in workspace.Ignored (exact RPG pattern)
    for _, handle in ipairs(Workspace.Ignored:GetChildren()) do
        -- Match RPG script exactly: any unanchored BasePart
        if handle:IsA("BasePart") and not handle.Anchored then
            -- Track first seen time
            if not grenadeTimers[handle] then
                grenadeTimers[handle] = tick()
                processedCount = processedCount + 1
            end
            
            -- Use handle.Position NOT handle.CFrame (RPG pattern)
            handle.Position = target_pos
            handle.BrickColor = BrickColor.new("Really red")
        end
    end
    
    -- Cleanup destroyed grenades
    for handle, _ in pairs(grenadeTimers) do
        if not handle or not handle.Parent then
            grenadeTimers[handle] = nil
        end
    end
end

-- Buy Grenades Button
sec:AddButton({ 
    Text = "Buy Grenades", 
    Func = function()
        local amount = BuyAmount.Value
        
        api:notify("Buying " .. amount .. " Grenades...", 2)
        
        for i = 1, amount do
            api:buy_item("[Grenade]")
            task.wait(0.1)
        end
    end 
})

-- Cleanup All Button
sec:AddButton({ 
    Text = "Reset Tracking", 
    Func = function()
        grenadeTimers = {}
        api:notify("Reset grenade tracking", 2)
    end 
})

-- Main Heartbeat loop (RPG pattern)
api:add_connection(RunService.Heartbeat:Connect(TeleportGrenades))

api:notify("Grenade TP V2 Loaded", 3)
