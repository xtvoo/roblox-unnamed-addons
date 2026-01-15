--[[
    OPTIMIZED "STICKY UPRIGHT" STOMP - FIXED VALUES
    - Uses api:get_ui_object():GetValue() for reliable updates
    - Forces UPRIGHT CFrame
    - 0ms Event Trigger
]]

api:set_lua_name("sticky_upright_stomp_v3")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")
local FireServer = MainEvent.FireServer
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new

-- UI Setup
local tabs = { main = api:AddTab("Stomp Logic") }
local group = tabs.main:AddLeftGroupbox("Settings")

group:AddToggle("stomp_enabled", { 
    Text = "Enable Sticky Stomp", 
    Default = false 
}):AddKeyPicker("stomp_bind", { 
    Default = "None", 
    Text = "Toggle Key", 
    Mode = "Toggle", 
    SyncToggleState = true 
})

group:AddSlider("stomp_height", { 
    Text = "Height Above Target", 
    Default = 3.5, 
    Min = 0, 
    Max = 10, 
    Rounding = 0.5, 
    Suffix = " studs" 
})

group:AddToggle("skip_dead", { Text = "Skip Dead", Default = true })
group:AddToggle("skip_sdeath", { Text = "Skip Already Stomped", Default = true })

-- Helper: Reliable Value Getter (The Fix)
local function get_val(flag)
    local obj = api:get_ui_object(flag)
    if obj then
        return obj:GetValue()
    end
    return nil
end

-- Helper: Fast Cache Lookup
local function get_upper_torso(player)
    local cache = api:get_character_cache(player)
    if not cache then return nil end
    return cache.UpperTorso or cache.Torso or cache.HumanoidRootPart
end

-- Helper: Status Check
local function is_valid_target(player)
    if not player then return false end
    local status = api:get_status_cache(player)
    if not status or not status["K.O"] then return false end
    
    if get_val("skip_dead") and status.Dead then return false end
    if get_val("skip_sdeath") and status.SDeath then return false end
    
    return true
end

-- MAIN LOGIC
local function execute_sticky_stomp(target_part)
    local my_char = LocalPlayer.Character
    if not my_char then return end
    local my_root = my_char:FindFirstChild("HumanoidRootPart")
    if not my_root then return end

    -- 1. PHYSICS GLUE
    sethiddenproperty(my_root, "PhysicsRepRootPart", target_part)

    -- 2. UPRIGHT POSITIONING (Now using get_val for live updates)
    if api:can_desync() then
        local target_pos = target_part.Position
        local height = get_val("stomp_height") or 3.5
        
        -- Upright CFrame (No Rotation)
        local upright_cf = CFrame_new(target_pos + Vector3_new(0, height, 0))
        
        api:set_desync_cframe(upright_cf)
    end

    -- 3. FIRE STOMP
    FireServer(MainEvent, "Stomp")
end

-- EVENT TRIGGER: 0ms Reaction
api:on_event("localplayer_hit_player", function(player_name, hit_part, damage, weapon)
    if not get_val("stomp_enabled") then return end
    
    local target = Players:FindFirstChild(player_name)
    if is_valid_target(target) then
        local target_part = get_upper_torso(target)
        if target_part then
            execute_sticky_stomp(target_part)
        end
    end
end)

-- LOOP TRIGGER: Backup & Continuous Glue
api:add_connection(RunService.Heartbeat:Connect(function()
    if not get_val("stomp_enabled") then return end

    local targets = {
        api:get_target_cache("silent").player,
        api:get_target_cache("ragebot").player
    }

    for _, target in ipairs(targets) do
        if is_valid_target(target) then
            local target_part = get_upper_torso(target)
            if target_part then
                execute_sticky_stomp(target_part)
                break 
            end
        end
    end
end))

-- CLEANUP
api:on_event("unload", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
    end
    api:notify("Sticky Stomp Unloaded", 2)
end)

api:notify("Sticky Stomp V3 Loaded", 3)
