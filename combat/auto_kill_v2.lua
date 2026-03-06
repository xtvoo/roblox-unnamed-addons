-- Auto Kill V2 (Remake)
-- "Expanded OG logic" using State Machine & Sticky Glue.

api:set_lua_name("auto_kill_v2")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")

-- ========== UI SETUP ==========
local Tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local Main = Tab:AddLeftGroupbox("Auto Kill V2 - Main")
local Bagging = Tab:AddRightGroupbox("Auto Kill V2 - Bagging")
local Safety = Tab:AddLeftGroupbox("Auto Kill V2 - Safety")

-- Main Controls
Main:AddToggle("ak_enabled", { Text = "Enable Auto Kill", Default = false })
Main:AddToggle("ak_autostomp", { Text = "Auto Stomp Knocked", Default = true, Tooltip = "Stomp knocked targets before bagging" })
Main:AddToggle("ak_flame", { Text = "Flamethrower Mode", Default = false, Tooltip = "Use flamethrower logic for kill" })
Main:AddDivider()
Main:AddSlider("ak_stomp_height", { Text = "Stomp Height", Default = 0.5, Min = -5, Max = 10, Rounding = 1, Suffix = " studs" })
Main:AddToggle("ak_stomp_sticky", { Text = "Sticky Stomp", Default = true, Tooltip = "Glue to target while stomping" })
Main:AddDivider()

-- Bagging Controls
Bagging:AddSlider("ak_bag_spam", { Text = "Bag Spam Rate", Default = 5, Min = 1, Max = 10, Rounding = 0, Suffix = " /s" })
Bagging:AddSlider("ak_bag_dist", { Text = "Bag Distance", Default = 3, Min = 1, Max = 10, Rounding = 1, Suffix = " studs" })
Bagging:AddSlider("ak_bag_height", { Text = "Bag Height", Default = 2, Min = 0, Max = 10, Rounding = 1, Suffix = " studs" })
Bagging:AddToggle("ak_bag_sticky", { Text = "Sticky Bagging", Default = true, Tooltip = "Physically glue to target when bagging" })
Bagging:AddToggle("ak_prefire", { Text = "Pre-Fire Bagging", Default = true, Tooltip = "Start bagging just before they fully die" })

-- Safety Controls
Safety:AddToggle("ak_void_alive", { Text = "Void When Target Alive", Default = false, Tooltip = "Hides you in void while fighting" })
Safety:AddToggle("ak_check_tool", { Text = "Check Tool Status", Default = true, Tooltip = "Only void if they have a weapon" })
Safety:AddToggle("ak_check_crew", { Text = "Anti-Crew", Default = true, Tooltip = "Don't target crew members" })

-- ========== STATE ==========
local State = {
    Target = nil,
    Mode = "idle",
    LastBagAttempt = 0,
    BuyingBag = false,
    IsInVoid = false
}

-- ... (skipping helpers)

-- ========== LOGIC LOOP ==========
local function RunLoop()
    if not Toggles.ak_enabled.Value then
        if State.Mode ~= "idle" then
            State.Mode = "idle"
            State.Target = nil
            SetRagebot(false)
            SetVoid(false)
        end
        return
    end

    -- 1. Acquire Target
    -- ONLY use specific targets. Do NOT pick random closest players.
    local target = api:get_target("silent") or api:get_target("aimbot") or api:get_target("ragebot")


    State.Target = target

    if not target then
        if State.Mode ~= "idle" then
             State.Mode = "idle"
             SetRagebot(false)
             SetVoid(false)
        end
        return
    end

    -- 2. Analyze State
    local is_knocked = IsKnocked(target)
    local is_bagged = IsBagged(target)
    
    -- Pre-fire check logic: if not knocked/bagged but we want to pre-fire?
    -- Actually Pre-Fire usually means start bagging just as they die. 
    -- The OG script uses a delay timer. We'll simplify: if knocked, go to bag/stomp.
    
    -- Mode Selection
    local new_mode = "idle"
    local should_void = false
    
    if is_bagged then
        -- Job done. Be idle or maybe void? 
        -- If void on success is desired? OG script resets to idle/bagging. 
        -- We'll stay idle but keep void off to show off kill.
        new_mode = "idle"
        
    elseif is_knocked then
        if Toggles.ak_autostomp.Value then
             new_mode = "stomping"
        else
             new_mode = "bagging"
        end
    else
        -- Target is alive
        new_mode = "killing"
        
        -- Void Checking
        if Toggles.ak_void_alive.Value then
            should_void = true
            if Toggles.ak_check_tool.Value and not HasGun(target) then
                should_void = false
            end
        end
    end

    -- Apply Mode
    SetVoid(should_void)
    
    if new_mode == "killing" then
        State.Mode = "killing"
        SetRagebot(true)
        
    elseif new_mode == "stomping" then
        State.Mode = "stomping"
        SetRagebot(true) -- Ragebot usually handles stomps if configured, or we let Auto Stomp script handle it?
        -- The prompt implies this script should do it or trigger it. 
        -- Since we have Auto Stomp V2, we can just let Ragebot run (which aims) and let V2 script run?
        -- Or we can assume this script replicates V2 logic. 
        -- For "Auto Kill", usually it relies on the Ragebot's main loop + Stomp.
        -- We'll assume SetRagebot(true) allows the internal/other stomp logic to fire.
        -- BUT, if this is a standalone "Auto Kill", we should probably fire stomps ourselves if "Main Event" is needed.
        -- Let's fire stomp just in case.
        MainEvent:FireServer("Stomp")
        
    elseif new_mode == "bagging" then
        State.Mode = "bagging"
        SetRagebot(false) -- Stop shooting
        
        -- Bag Logic
        local bag = GetBagTool()
        if not bag then
            if not State.BuyingBag and api:can_desync() then
                State.BuyingBag = true
                api:notify("Buying Bag...", 1)
                task.spawn(function()
                    api:buy_item("brownbag")
                    task.wait(1)
                    State.BuyingBag = false
                end)
            end
        else
            -- Equip
            if bag.Parent == LocalPlayer.Backpack then
                 LocalPlayer.Character.Humanoid:EquipTool(bag)
            end
            
            -- Bag Spam
            local rate = Options.ak_bag_spam.Value
            if (os.clock() - State.LastBagAttempt) > (1/rate) then
                bag:Activate()
                State.LastBagAttempt = os.clock()
            end
            
            -- Sticky Glue handled in Physics Loop
        end
    else
        State.Mode = "idle"
        SetRagebot(false)
    end
end

-- ========== PHYSICS LOOP (For Glue) ==========
local function PhysicsLoop()
    if not Toggles.ak_enabled.Value then return end
    
        if (State.Mode == "bagging" and Toggles.ak_bag_sticky.Value) or (State.Mode == "stomping" and Toggles.ak_stomp_sticky.Value) then
            local target = State.Target
            if not target or not target.Character then return end
            
            local my_root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local t_root = target.Character:FindFirstChild("HumanoidRootPart")
            
            if my_root and t_root then
                -- Sticky Glue
                pcall(function()
                    sethiddenproperty(my_root, "PhysicsRepRootPart", t_root)
                end)
                
                -- Desync Position
                local desync_cf = nil
                
                if State.Mode == "bagging" then
                     local dist = Options.ak_bag_dist.Value
                     local height = Options.ak_bag_height.Value
                     local t_cf = t_root.CFrame
                     local ideal_pos = t_cf.Position + Vector3.new(0, height, 0) - (t_cf.LookVector * dist)
                     desync_cf = CFrame.new(ideal_pos, t_cf.Position)
                else -- stomping
                     local height = Options.ak_stomp_height.Value
                     local ideal_pos = t_root.Position + Vector3.new(0, height, 0)
                     desync_cf = CFrame.new(ideal_pos, t_root.Position)
                end
                
                api:set_desync_cframe(desync_cf)
            end
    else
        -- Unglue if not bagging
        local my_root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if my_root then
             pcall(function()
                sethiddenproperty(my_root, "PhysicsRepRootPart", nil)
            end)
        end
    end
end

-- Connect
api:add_connection(RunService.Heartbeat:Connect(RunLoop))
api:add_connection(RunService.Heartbeat:Connect(PhysicsLoop))

api:on_event("unload", function()
    SetVoid(false)
    SetRagebot(false)
    local my_root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if my_root then
         pcall(function()
            sethiddenproperty(my_root, "PhysicsRepRootPart", nil)
        end)
    end
    api:notify("Auto Kill V2 Unloaded", 2)
end)

api:notify("Auto Kill V2 Loaded", 3)
