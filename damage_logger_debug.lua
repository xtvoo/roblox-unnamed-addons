-- ========================================
-- DAMAGE LOGGER DEBUG - Unnamed Addon
-- Logs damage to your Silent Aim target
-- ========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
pcall(function() api:set_lua_name("Damage Logger Debug") end)

-- ========================================
-- UI SETUP
-- ========================================
local tab = api:GetTab("misc") or api:AddTab("misc")
local group = tab:AddLeftGroupbox("Damage Logger Debug")

-- ========================================
-- DA HOOD WEAPONS
-- ========================================
local MELEE_WEAPONS = {
    "knife", "bat", "sledgehammer", "pitchfork", "shovel", "stopsign", 
    "whip", "pencil", "pepperspray", "taser", "fist", "punch"
}

local GUN_WEAPONS = {
    "glock", "revolver", "silencer", "smg", "shotgun", "double-barrel sg",
    "drum-shotgun", "drumgun", "ak47", "ar", "aug", "p90", "silencerar",
    "lmg", "rifle", "tacticalshotgun", "flintlock", "rpg", "grenadelauncher",
    "flamethrower"
}

-- ========================================
-- STATE
-- ========================================
local damage_log = {}
local MAX_LOG_ENTRIES = 100
local player_health_cache = {}
local logging_enabled = false
local notify_enabled = false
local log_all_damage = false -- false = only silent aim target
local melee_range = 12

local function formatTime()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

-- ========================================
-- GET SILENT AIM TARGET
-- ========================================
local function getSilentAimTarget()
    -- Try multiple ways to get the silent aim target
    local target = nil
    
    -- Method 1: api:get_target_cache
    pcall(function()
        local cache = api:get_target_cache("silentaim")
        if cache and type(cache) == "table" then
            for _, t in pairs(cache) do
                if typeof(t) == "Instance" then
                    if t:IsA("Player") then
                        target = t
                    elseif t:IsA("Model") then
                        target = Players:GetPlayerFromCharacter(t)
                    end
                    if target then break end
                end
            end
        end
    end)
    
    -- Method 2: Check silentaim_target UI object
    if not target then
        pcall(function()
            local sa_target = api:get_ui_object("silentaim_target")
            if sa_target and sa_target.Value then
                local val = sa_target.Value
                if typeof(val) == "Instance" and val:IsA("Player") then
                    target = val
                elseif type(val) == "string" and val ~= "" then
                    target = Players:FindFirstChild(val)
                end
            end
        end)
    end
    
    -- Method 3: Check _G for silent aim target
    if not target then
        pcall(function()
            if _G.SilentAimTarget then
                local t = _G.SilentAimTarget
                if typeof(t) == "Instance" then
                    if t:IsA("Player") then target = t
                    elseif t:IsA("Model") then target = Players:GetPlayerFromCharacter(t) end
                end
            end
        end)
    end
    
    return target
end

local function isOurTarget(player)
    if log_all_damage then return true end
    local target = getSilentAimTarget()
    return target and target == player
end

-- ========================================
-- WEAPON DETECTION
-- ========================================
local function getWeaponType(tool)
    if not tool then return "Fists" end
    local name = tool.Name:lower()
    
    for _, w in ipairs(MELEE_WEAPONS) do
        if name:find(w) then return "Melee (" .. tool.Name .. ")" end
    end
    
    for _, w in ipairs(GUN_WEAPONS) do
        if name:find(w) then return "Gun (" .. tool.Name .. ")" end
    end
    
    return "Tool (" .. tool.Name .. ")"
end

local function logDamage(victim_name, attacker_name, damage, weapon_type, extra_info)
    if not logging_enabled then return end
    
    local entry = {
        time = formatTime(),
        victim = victim_name or "Unknown",
        attacker = attacker_name or "Unknown",
        damage = damage or 0,
        weapon = weapon_type or "Unknown",
        extra = extra_info or ""
    }
    
    table.insert(damage_log, 1, entry)
    while #damage_log > MAX_LOG_ENTRIES do table.remove(damage_log) end
    
    local log_msg = string.format("[%s] %s -> %s (%.1f) [%s]", 
        entry.time, entry.attacker, entry.victim, entry.damage, entry.weapon)
    
    print("[TARGET DMG] " .. log_msg)
    
    if notify_enabled then
        api:notify(log_msg, 3)
    end
end

-- ========================================
-- MAINEVENT HOOK (Bullets)
-- ========================================
if MainEvent then
    api:add_connection(MainEvent.OnClientEvent:Connect(function(mode, ...)
        if not logging_enabled then return end
        local args = {...}
        
        if mode == "ClientBullet" then
            local shooter = args[1]
            local hit_part = args[2]
            
            if shooter and typeof(shooter) == "Instance" and shooter:IsA("Model") then
                local shooter_player = Players:GetPlayerFromCharacter(shooter)
                if shooter_player == LocalPlayer then return end -- ignore our shots
                
                local shooter_name = shooter_player and shooter_player.Name or shooter.Name
                
                if hit_part and typeof(hit_part) == "Instance" then
                    local char = hit_part:FindFirstAncestorOfClass("Model")
                    if char then
                        local victim_player = Players:GetPlayerFromCharacter(char)
                        if victim_player and isOurTarget(victim_player) then
                            local weapon = "Gun"
                            local tool = shooter:FindFirstChildWhichIsA("Tool")
                            if tool then weapon = getWeaponType(tool) end
                            logDamage(victim_player.Name, shooter_name, 0, weapon, "shot")
                        end
                    end
                end
            end
        end
    end))
end

-- ========================================
-- HEALTH MONITORING (Melee/All damage)
-- ========================================
local function findNearbyAttacker(victim_char, victim_player)
    local victim_pos = victim_char:FindFirstChild("HumanoidRootPart")
    if not victim_pos then return nil, "Unknown", "Unknown" end
    victim_pos = victim_pos.Position
    
    local closest_dist = melee_range
    local closest_attacker = nil
    local weapon_type = "Fists"
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= victim_player and p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - victim_pos).Magnitude
                if dist < closest_dist then
                    closest_dist = dist
                    closest_attacker = p
                    local tool = p.Character:FindFirstChildWhichIsA("Tool")
                    weapon_type = getWeaponType(tool)
                end
            end
        end
    end
    
    if closest_attacker then
        return closest_attacker, closest_attacker.Name, weapon_type
    end
    return nil, "Unknown", "Unknown"
end

local function monitorPlayerHealth(player)
    if player == LocalPlayer then return end
    
    local function setupHealthMonitor(character)
        if not character then return end
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        
        player_health_cache[player] = humanoid.Health
        
        api:add_connection(humanoid.HealthChanged:Connect(function(new_health)
            if not logging_enabled then return end
            if not isOurTarget(player) then return end -- Only log for our target
            
            local old_health = player_health_cache[player] or humanoid.MaxHealth
            local damage = old_health - new_health
            player_health_cache[player] = new_health
            
            if damage > 0.1 then
                local creator = humanoid:FindFirstChild("creator") or humanoid:FindFirstChild("Creator")
                local attacker_name = nil
                local weapon_type = nil
                
                if creator and creator.Value and creator.Value:IsA("Player") then
                    if creator.Value == LocalPlayer then return end -- ignore our damage
                    attacker_name = creator.Value.Name
                    if creator.Value.Character then
                        local tool = creator.Value.Character:FindFirstChildWhichIsA("Tool")
                        weapon_type = getWeaponType(tool)
                    end
                end
                
                if not attacker_name then
                    local _, name, weapon = findNearbyAttacker(character, player)
                    attacker_name = name
                    weapon_type = weapon
                end
                
                logDamage(player.Name, attacker_name, damage, weapon_type or "Unknown", "")
            end
        end))
    end
    
    if player.Character then setupHealthMonitor(player.Character) end
    api:add_connection(player.CharacterAdded:Connect(setupHealthMonitor))
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(monitorPlayerHealth, player)
end

api:add_connection(Players.PlayerAdded:Connect(function(player)
    task.spawn(monitorPlayerHealth, player)
end))

api:add_connection(Players.PlayerRemoving:Connect(function(player)
    player_health_cache[player] = nil
end))

-- ========================================
-- UI
-- ========================================
group:AddToggle("dmg_log_enabled", { 
    Text = "Enable Logging", 
    Default = false,
    Callback = function(val) 
        logging_enabled = val 
        if val then api:notify("[DMG LOG] Watching your silent aim target", 3) end
    end
})

group:AddToggle("dmg_log_all", { 
    Text = "Log All Players (not just target)", 
    Default = false,
    Callback = function(val) log_all_damage = val end
})

group:AddToggle("dmg_log_notify", { 
    Text = "Show Notifications", 
    Default = false,
    Callback = function(val) notify_enabled = val end
})

group:AddSlider("dmg_melee_range", {
    Text = "Melee Detection Range",
    Default = 12, Min = 5, Max = 25, Rounding = 0,
    Callback = function(val) melee_range = val end
})

group:AddButton("Print Log", function()
    print("\n========== TARGET DAMAGE LOG ==========")
    for i = 1, math.min(20, #damage_log) do
        local e = damage_log[i]
        print(string.format("[%s] %s -> %s (%.1f) [%s]", 
            e.time, e.attacker, e.victim, e.damage, e.weapon))
    end
    print("========================================\n")
    api:notify("Printed to F9", 2)
end)

group:AddButton("Clear Log", function()
    damage_log = {}
    api:notify("Log cleared", 2)
end)

api:notify("Damage Logger Loaded", 3)
