-- Auto Stomp V2 (Remake)
-- "Instant", Aggressive, Void-Compatible.

api:set_lua_name("auto_stomp_v2")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")

-- Variables
local CurrentTarget = nil
local IsStomping = false

-- UI Setup
local Tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local Group = Tab:AddRightGroupbox("Auto Stomp V2")

-- Controls
Group:AddToggle("as_enabled", { Text = "Enable Auto Stomp", Default = false })
Group:AddLabel("Keybind"):AddKeyPicker("as_keybind", { Default = "None", Text = "Stomp Bind", Mode = "Toggle" })

Group:AddDivider()

Group:AddToggle("as_void", { Text = "Stomp in Void", Default = true, Tooltip = "Works even if target is in void" })
Group:AddToggle("as_sticky", { Text = "Aggressive Sticky", Default = true, Tooltip = "Uses hidden property to glue character" })
Group:AddToggle("as_skip_dead", { Text = "Skip Dead", Default = true, Tooltip = "Don't stomp if already dead (saves FPS)" })
Group:AddToggle("as_skip_ko", { Text = "Skip Knocked", Default = false, Tooltip = "If false, stomps even if they aren't fully dead yet" })

Group:AddDivider()

Group:AddSlider("as_height", { Text = "Height", Default = 0, Min = -5, Max = 5, Rounding = 1, Suffix = " studs" })
Group:AddSlider("as_radius", { Text = "Scan Radius", Default = 15, Min = 5, Max = 50, Rounding = 0, Suffix = " studs", Tooltip = "How far to check for stompable targets" })

-- Helpers
local function IsValid(player)
    if not player or not player.Character then return false end
    
    local status = api:get_status_cache(player)
    if not status then return true end -- Assume valid if no cache (aggressive)
    
    if Toggles.as_skip_dead.Value and status.Dead then return false end
    -- If we want to stomp "no matter what", we usually ignore KO state unless specifically asked to skip
    if Toggles.as_skip_ko.Value and status["K.O"] then return false end
    
    return true
end

local function GetStompTarget()
    -- Only check specific targets as requested
    local target = api:get_target("silent") or api:get_target("ragebot")
    
    if target and IsValid(target) then
        -- Strictly require KNOCKED status
        local status = api:get_status_cache(target)
        if status and (status["K.O"] or status.SDeath) then
            return target
        end
    end
    
    return nil
end

-- Main Loop (Optimized)
local function RunLoop()
    local enabled = (Toggles.as_enabled and Toggles.as_enabled.Value) or (Options.as_keybind and Options.as_keybind.GetState())
    if not enabled then
        CurrentTarget = nil
        pcall(function() sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil) end)
        return 
    end

    local target = GetStompTarget()
    CurrentTarget = target
    
    if not target then 
         -- If no target, unglue immediately
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function() sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil) end)
        end
        return 
    end
    
    local my_char = LocalPlayer.Character
    local target_char = target.Character
    
    if not my_char or not target_char then return end
    
    local my_root = my_char:FindFirstChild("HumanoidRootPart")
    local target_root = target_char:FindFirstChild("HumanoidRootPart") or target_char:FindFirstChild("UpperTorso")
    
    if not my_root or not target_root then return end

    -- Calculation
    local stomp_pos = target_root.Position + Vector3.new(0, Options.as_height.Value, 0)
    
    -- Void Check logic (Target IS in void)
    -- User wants to stomp even if they are in void, so we act if toggle is ON.
    if not Toggles.as_void.Value and stomp_pos.Y < -50 then
        return 
    end

    local look_cf = CFrame.new(stomp_pos, target_root.Position)
    
    -- Execution
    pcall(function()
        -- 1. Physics Sticky (Aggressive)
        -- User asked: "set hiddenprpoety and desync onto there torso"
        if Toggles.as_sticky.Value and sethiddenproperty then
             sethiddenproperty(my_root, "PhysicsRepRootPart", target_root)
        end
        
        -- 2. Teleport
        if api:can_desync() then
            api:set_desync_cframe(look_cf)
        end
        
        -- 3. Stomp Action
        MainEvent:FireServer("Stomp")
    end)
end

-- Hook to Heartbeat for max speed
api:add_connection(RunService.Heartbeat:Connect(RunLoop))

api:on_event("unload", function()
    api:notify("Auto Stomp V2 Unloaded", 2)
end)

api:notify("Auto Stomp V2 Loaded", 3)
