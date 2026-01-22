api:set_lua_name("haydens auto kitten bagger 9000")


local Handler = loadstring(game:HttpGet("https://raw.githubusercontent.com/XK5NG/XK5NG.github.io/main/Handler"))()
local Players = Handler:CloneRef("Players")
local RunService = Handler:CloneRef("RunService")
local Workspace = Handler:CloneRef("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ========== UI SETUP ==========
-- ========== UI SETUP ==========
local Tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local Main = Tab:AddLeftGroupbox("Auto Kill - Main")
local Bagging = Tab:AddRightGroupbox("Auto Kill - Bagging")
local Safety = Tab:AddLeftGroupbox("Auto Kill - Safety")

Main:AddToggle("MasterSwitch", { Text = "Enable Auto Bag", Default = false })
Main:AddDropdown("KillModeDropdown", { 
    Values = {"Normal Ragebot", "Flamethrower Hack"}, 
    Default = 1, 
    Text = "Kill Method" 
})
Main:AddToggle("AutoStomp", {
    Text = "Auto Stomp Knocked",
    Default = true,
    Tooltip = "Stomp knocked targets before bagging"
})

Main:AddToggle("SilentAimOnly", {
    Text = "Silent Aim Target Only",
    Default = false,
    Tooltip = "Only target players locked by silent aim (ignoring proximity)"
})

Bagging:AddDropdown("BagStrategy", {
    Values = {"Adaptive", "Behind", "Below", "Aggressive Spin"},
    Default = 1,
    Text = "Bag Position Strategy",
    Tooltip = "Adaptive tries multiple positions"
})
Bagging:AddSlider("BagSpamRate", { 
    Text = "Bag Spam Rate", 
    Default = 5, 
    Min = 1, 
    Max = 30, 
    Rounding = 0, 
    Suffix = " bags/sec" 
})
Bagging:AddSlider("BagDistance", {
    Text = "Behind Distance",
    Default = 2.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Suffix = " studs"
})
Bagging:AddSlider("BagHeight", {
    Text = "Below Height",
    Default = 2,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Suffix = " studs"
})
Bagging:AddToggle("AdaptiveBag", { 
    Text = "Auto Adjust Position", 
    Default = true, 
    Tooltip = "Changes position if bag fails" 
})
Bagging:AddToggle("SpawnCamp", { 
    Text = "Spawn Camp (Pre-Buy)", 
    Default = true, 
    Tooltip = "Buys and equips bag WHILE target is dead for instant spawn kill" 
})
Bagging:AddDivider()
Bagging:AddToggle("PreFireBag", {
    Text = "Pre-Fire Bagging",
    Default = true,
    Tooltip = "Start bagging before they fully die"
})
Bagging:AddSlider("PreFireDelay", {
    Text = "Pre-Fire Delay",
    Default = 0.2,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Suffix = " seconds",
    Tooltip = "Time after bag removal to start re-bagging"
})


Safety:AddToggle("VoidWhenDead", {
    Text = "Void When Target Dead",
    Default = true,
    Tooltip = "Go to void coordinates when target is confirmed dead"
})
Safety:AddToggle("CheckToolStatus", {
    Text = "Check Tool Status",
    Default = true,
    Tooltip = "Only target players locked by silent aim (ignoring aimbot/proximity)"
})

-- Multi-Target Dropdown
local PlayerDropdown = Main:AddDropdown("TargetList", {
    Values = {},
    Default = {},
    Multi = true,
    Text = "Select Targets",
    Tooltip = "Prioritize specific players"
})

-- Player Search Input
Main:AddInput("PlayerSearchInput", {
    Default = "",
    Numeric = false,
    Finished = true,
    Text = "Add Target (User/Display)",
    Tooltip = "Type name to auto-select player",
    Placeholder = "Username or Display Name",
})
Safety:AddToggle("DebugMode", { Text = "Debug Notifications", Default = false })
Safety:AddToggle("DeepDebug", { 
    Text = "Deep Debug (Timing Reports)", 
    Default = false, 
    Tooltip = "Logs precise milliseconds of every action to console (F9)" 
})

-- ========== FLAGS ==========
local Flags = {
    RageTarget = api:get_ui_object("ragebot_targets"),
    RageFlame  = api:get_ui_object("ragebot_flame"),
    VoidProt   = api:get_ui_object("character_prot_void"),
}

-- ========== STATE ==========
local State = {
    Target = nil,
    IsBagged = false,
    IsKnocked = false,
    LastSetTarget = "",
    BuyingBag = false,
    LastBuyTime = 0,
    BagAttempts = 0,
    LastBagCheck = 0,
    LastBagAttempt = 0,
    Mode = "idle",
    CurrentStrategy = 1,
    StrategyFailCount = 0,
    LastBagSuccess = 0,
    BagRemovedTime = 0,
    WasJustBagged = false,
    
    -- Debug Timestamps
    T_Detect = 0,
    T_Vulnerable = 0,
    T_StartBag = 0,
    T_Equip = 0,
    T_Click = 0,
    T_BagStart = 0,
    T_Death = 0, -- When did they die?
    T_Respawn = 0, -- When did they spawn?
    DebugActive = false,
}


local VoidCFrame = CFrame.new(18812581888888, 99999999999999999999999999999, 998235235621111)
local TargetRespawnConnection = nil


-- ========== PLAYER LIST MANAGEMENT ==========
local function GetPlayerFormat(player)
    return string.format("%s (@%s)", player.DisplayName, player.Name)
end

local function UpdatePlayerList()
    local values = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(values, GetPlayerFormat(player))
        end
    end
    PlayerDropdown:SetValues(values)
end

api:add_connection(Players.PlayerAdded:Connect(UpdatePlayerList))
api:add_connection(Players.PlayerRemoving:Connect(function() task.delay(0.1, UpdatePlayerList) end))
UpdatePlayerList()

Options.PlayerSearchInput:OnChanged(function(val)
    if not val or type(val) ~= "string" then return end
    
    -- Trim whitespace
    val = val:match("^%s*(.-)%s*$")
    if val == "" then return end
    
    local bestMatch = nil
    local bestScore = 0
    local lowerVal = val:lower()
    
    -- Score rules: Exact=3, StartsWith=2, Contains=1
    -- Tie-breaker: Shorter name length (closer to input)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pName = p.Name:lower()
            local pDisplay = p.DisplayName:lower()
            local pFormatted = GetPlayerFormat(p):lower()
            
            local currentScore = 0
            
            -- Check Name
            if pName == lowerVal then currentScore = 3
            elseif pName:find("^" .. lowerVal, 1, false) then currentScore = 2
            elseif pName:find(lowerVal, 1, true) then currentScore = 1
            end
            
            -- Check DisplayName (take highest of existing)
            if pDisplay == lowerVal then currentScore = math.max(currentScore, 3)
            elseif pDisplay:find("^" .. lowerVal, 1, false) then currentScore = math.max(currentScore, 2)
            elseif pDisplay:find(lowerVal, 1, true) then currentScore = math.max(currentScore, 1)
            end
            
            -- Check Formatted (mainly for contains/starts)
            if pFormatted:find(lowerVal, 1, true) then currentScore = math.max(currentScore, 1) end
            
            if currentScore > bestScore then
                bestMatch = p
                bestScore = currentScore
            elseif currentScore == bestScore and bestScore > 0 then
                -- Tie-breaker: Pick the one with shorter name (closer match length)
                if bestMatch and #p.Name < #bestMatch.Name then
                    bestMatch = p
                end
            end
        end
    end
    
    if bestMatch then
        local found = bestMatch
        local key = GetPlayerFormat(found)
        local current = Options.TargetList.Value
        
        if not current[key] then
            current[key] = true
            Options.TargetList:SetValue(current)
            api:notify("Added " .. found.Name .. " to targets!", 2)
        else
            api:notify(found.Name .. " is already selected.", 2)
        end
        
        -- Clear input (this might re-trigger but early return handles it)
        Options.PlayerSearchInput:SetValue("")
    else
        api:notify("No player found matching: " .. val, 2)
        Options.PlayerSearchInput:SetValue("")
    end
end)

-- ========== BAG POSITION STRATEGIES ==========
local BagStrategies = {
    function(targetRoot)
        local distance = Options.BagDistance and Options.BagDistance.Value or 2.5
        local height = Options.BagHeight and Options.BagHeight.Value or 2
        local behind = targetRoot.CFrame.LookVector * -distance
        local below = Vector3.new(0, -height, 0)
        return CFrame.new(targetRoot.Position + behind + below, targetRoot.Position)
    end,
    function(targetRoot)
        local height = Options.BagHeight and Options.BagHeight.Value or 2
        local below = Vector3.new(0, -(height + 1), 0)
        return CFrame.new(targetRoot.Position + below, targetRoot.Position)
    end,
    function(targetRoot)
        local distance = Options.BagDistance and Options.BagDistance.Value or 2.5
        local height = Options.BagHeight and Options.BagHeight.Value or 2
        local behind = targetRoot.CFrame.LookVector * -(distance + 0.5)
        local below = Vector3.new(0, -(height + 0.5), 0)
        return CFrame.new(targetRoot.Position + behind + below, targetRoot.Position)
    end,
    function(targetRoot)
        local distance = Options.BagDistance and Options.BagDistance.Value or 2.5
        local height = Options.BagHeight and Options.BagHeight.Value or 2
        local left = targetRoot.CFrame.RightVector * -distance
        local below = Vector3.new(0, -height, 0)
        return CFrame.new(targetRoot.Position + left + below, targetRoot.Position)
    end,
    function(targetRoot)
        local distance = Options.BagDistance and Options.BagDistance.Value or 2.5
        local height = Options.BagHeight and Options.BagHeight.Value or 2
        local right = targetRoot.CFrame.RightVector * distance
        local below = Vector3.new(0, -height, 0)
        return CFrame.new(targetRoot.Position + right + below, targetRoot.Position)
    end,
    function(targetRoot)
        local distance = Options.BagDistance and Options.BagDistance.Value or 2.5
        local height = Options.BagHeight and Options.BagHeight.Value or 2
        local angle = (tick() % (math.pi * 2))
        local offset = Vector3.new(
            math.cos(angle) * distance, 
            -height, 
            math.sin(angle) * distance
        )
        return CFrame.new(targetRoot.Position + offset, targetRoot.Position)
    end,
}

-- ========== HELPER FUNCTIONS ==========
local function DebugLog(message)
    if Toggles.DebugMode and Toggles.DebugMode.Value then
        pcall(function()
             appendfile("active_bagger_logs.txt", "[DEBUG] " .. message .. "\n")
        end)
    end
end

local function UpdateTargetUI(name)
    if Flags.RageTarget and State.LastSetTarget ~= name then
        State.LastSetTarget = name
        Flags.RageTarget:SetValue(name)
    end
end

local function SetFlameMode(enabled)
    if Flags.RageFlame and Flags.RageFlame.Value ~= enabled then
        Flags.RageFlame:SetValue(enabled)
    end
end

local function SetVoid(enabled)
    if Flags.VoidProt and Flags.VoidProt.Value ~= enabled then
        Flags.VoidProt:SetValue(enabled)
    end
end

local function GetBagTool()
    if not LocalPlayer.Character then return nil end
    local bag = LocalPlayer.Character:FindFirstChild("[BrownBag]")
    if not bag then
        bag = LocalPlayer.Backpack:FindFirstChild("[BrownBag]")
    end
    return bag
end

local function IsBagged(target)
    if not target or not target.Character then return false end
    local TargetModel = Workspace.Players.Model:FindFirstChild(target.Name)
    if not TargetModel then return false end
    
    return TargetModel:FindFirstChild("Christmas_Sock") ~= nil or 
           TargetModel:FindFirstChild("BrownBag") ~= nil or
           TargetModel:FindFirstChild("Bag") ~= nil
end

local function IsKnocked(player)
    if not player then return false end
    
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    
    return statusCache["K.O"] == true
end

local function IsTargetValid(player)
    if not player or not player.Character then return false end
    
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    
    -- Don't filter out knocked players anymore
    if statusCache.Dead or statusCache.Grabbed then
        return false
    end
    
    
    local charCache = api:get_character_cache(player)
    if not charCache or not charCache.HumanoidRootPart then return false end
    
    return true
end

local function IsDead(player)
    if not player then return false end
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    return statusCache.Dead == true
end


local function TargetHasGun(target)
    if not target or not target.Character then return false end
    
    local tool = target.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    if not tool:FindFirstChild("Handle") then return false end
    
    local gunPatterns = {
        "Shotgun", "Rifle", "Revolver", "SMG", 
        "AR", "AK47", "LMG", "TacticalShotgun",
        "Double-Barrel", "Silencer"
    }
    
    for _, pattern in ipairs(gunPatterns) do
        if string.find(tool.Name, pattern) then
            return true
        end
    end
    
    return false
end


local function ShouldVoidFromTarget()
   -- Deprecated/Removed feature
   return false
end


local function ShouldStartBagging()
    if not (Toggles.PreFireBag and Toggles.PreFireBag.Value) then
        return false
    end
    
    if not State.WasJustBagged then
        return false
    end
    
    local delay = Options.PreFireDelay and Options.PreFireDelay.Value or 0.2
    local timeSinceRemoval = tick() - State.BagRemovedTime
    
    return timeSinceRemoval >= delay
end

local function TriggerBuyBag()
    if api:can_desync() and not State.BuyingBag then
        local currentTime = tick()
        local rbStatus = api:get_ragebot_status()
        
        -- Ignore cooldown if we are spawn camping (WE NEED BAG NOW)
        local ignoreCooldown = Toggles.SpawnCamp and Toggles.SpawnCamp.Value
        
        if rbStatus ~= "buying" and (ignoreCooldown or currentTime - State.LastBuyTime > 2) then
            State.BuyingBag = true
            State.LastBuyTime = currentTime
            
            task.spawn(function()
                DebugLog("Buying bag (Crouch Glitch)...")
                
                -- Force Crouch
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.05)

                
                -- Double Buy Attempt
                api:buy_item("brownbag", false, true)
                task.wait(0.1)
                api:buy_item("brownbag", false, true)
                
                task.wait(0.2)
                -- Uncrouch
                vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                
                task.wait(1.0)
                State.BuyingBag = false
            end)
        end
    end
end

-- ========== BAG OPERATIONS ==========
local function UseBag()
    local currentTime = tick()
    local spamRate = Options.BagSpamRate and Options.BagSpamRate.Value or 5
    local spamDelay = 1 / spamRate
    
    if currentTime - State.LastBagAttempt < spamDelay then
        return false
    end
    
    local Bag = GetBagTool()
    
    if not Bag then 
        TriggerBuyBag()
        return false
    end
    
    if Bag.Parent == LocalPlayer.Backpack then
        if State.T_Equip == 0 then State.T_Equip = os.clock() end
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(Bag)
        end
    end
    
    if Bag.Parent == LocalPlayer.Character then
        if State.T_Equip == 0 then State.T_Equip = os.clock() end -- Handle pre-equipped or instant switch
        State.T_Click = os.clock()
        Bag:Activate()
        State.LastBagAttempt = currentTime
        State.BagAttempts = State.BagAttempts + 1
        return true
    end
    
    return false
end

local function GetBagPosition(targetRoot)
    local strategy = Options.BagStrategy and Options.BagStrategy.Value or "Adaptive"
    
    if strategy == "Adaptive" then
        if Toggles.AdaptiveBag and Toggles.AdaptiveBag.Value then
            if tick() - State.LastBagSuccess > 2 or State.StrategyFailCount > 10 then
                State.CurrentStrategy = (State.CurrentStrategy % #BagStrategies) + 1
                State.StrategyFailCount = 0
                DebugLog("Strategy: " .. State.CurrentStrategy)
            end
        end
        return BagStrategies[State.CurrentStrategy](targetRoot)
    elseif strategy == "Behind" then
        return BagStrategies[1](targetRoot)
    elseif strategy == "Below" then
        return BagStrategies[2](targetRoot)
    elseif strategy == "Aggressive Spin" then
        return BagStrategies[6](targetRoot)
    end
    
    return BagStrategies[1](targetRoot)
end

-- ========== MAIN LOGIC LOOP ==========
-- ========== MAIN LOGIC LOOP (OPTIMIZED) ==========
-- Using Heartbeat for frame-perfect execution instead of task.wait loop
api:add_connection(RunService.Heartbeat:Connect(function(dt)
    -- Global Bag Maintenance (Pre-Buy)
    -- If SpawnCamp is on, ALWAYS ensure we have a bag, regardless of target
    if Toggles.SpawnCamp and Toggles.SpawnCamp.Value then
        local bag = GetBagTool()
        if not bag then
            TriggerBuyBag()
        end
    end
    
    if not (Toggles.MasterSwitch and Toggles.MasterSwitch.Value) then
        if State.Mode ~= "idle" then
            api:set_ragebot(false)
            SetFlameMode(false)
            SetVoid(false)
            State.Mode = "idle"
            State.LastSetTarget = ""
            State.BuyingBag = false
            State.WasJustBagged = false
            State.ShouldVoid = false
        end
        return
    end
    
    -- Get target
    local NewTarget = nil
    
    -- 1. Check Dropdown (Batch Priority: All Unbagged > Then Kill)
    if Options.TargetList then
        local selected_entries = Options.TargetList.Value
        local specific_targets = {}
        
        for name_str, is_selected in pairs(selected_entries) do
            if is_selected then
                local username = name_str:match("@(.+)")
                if not username then username = name_str:match("%((.+)%)") end
                
                if username then
                    username = username:gsub("%)", "")
                    local p = Players:FindFirstChild(username)
                    if p then
                        table.insert(specific_targets, p)
                    end
                end
            end
        end
        
        if #specific_targets > 0 then
            local found_unbagged = nil
            local found_bagged_alive = nil
            
            for _, p in ipairs(specific_targets) do
                if IsTargetValid(p) then
                    if not IsBagged(p) then
                        -- FOUND AN UNBAGGED TARGET -> PRIORITIZE THIS
                        found_unbagged = p
                        break -- Stop searching, we must bag this one first
                    elseif not found_bagged_alive then
                            -- Found a bagged one, keep as backup if all others are bagged
                            found_bagged_alive = p
                    end
                end
            end
            
            if found_unbagged then
                NewTarget = found_unbagged
            elseif found_bagged_alive then
                NewTarget = found_bagged_alive
            end
        end
    end
    
    -- 2. Silent Aim / Fallback (Priority #2)
    -- Only check if SilentAimOnly is ENABLED. If disabled, we ignore API targets and use Proximity/List.
    if not NewTarget and (Toggles.SilentAimOnly and Toggles.SilentAimOnly.Value) then
        NewTarget = api:get_target("silent") or api:get_target("aimbot")
    end

    
    -- 3. Proximity Fallback (Priority #3)
    -- Only if SilentAimOnly is OFF
    if not NewTarget and not (Toggles.SilentAimOnly and Toggles.SilentAimOnly.Value) then
        local MyChar = LocalPlayer.Character
        if MyChar then
            local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
            if MyRoot then
                local ClosestDist = 150 -- Max distance
                local ClosestPlr = nil
                
                for _, Player in ipairs(Players:GetPlayers()) do
                    if Player ~= LocalPlayer and IsTargetValid(Player) then
                        local charCache = api:get_character_cache(Player)
                        if charCache and charCache.HumanoidRootPart then
                            local Dist = (charCache.HumanoidRootPart.Position - MyRoot.Position).Magnitude
                            if Dist < ClosestDist then
                                ClosestDist = Dist
                                ClosestPlr = Player
                            end
                        end
                    end
                end
                
                NewTarget = ClosestPlr
            end
        end
    end

    
    -- RETENTION: If NewTarget is nil, but current State.Target is Dead, keep it to void them
    if not NewTarget and State.Target and IsDead(State.Target) then
            NewTarget = State.Target
    end

    -- Target changed
    if State.Target ~= NewTarget then
        State.Target = NewTarget
        State.T_Detect = os.clock() -- [Debug]
        State.T_Vulnerable = 0
        State.T_StartBag = 0
        State.T_Equip = 0
        State.T_Click = 0
        State.T_BagStart = 0 -- Track when they were bagged
        State.BagAttempts = 0
        State.CurrentStrategy = 1
        State.StrategyFailCount = 0
        State.WasJustBagged = false
        State.ShouldVoid = false
        State.IsKnocked = false
        
        -- FORCE RESET MODE & GLUE
        State.Mode = "idle"
        api:set_ragebot(false)
        SetFlameMode(false)
        SetVoid(false)
        State.BuyingBag = false -- Reset buying state
        
        pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
                end
        end)
        
        -- Manage Respawn Connection
        if TargetRespawnConnection then
            TargetRespawnConnection:Disconnect()
            TargetRespawnConnection = nil
        end
        
        if NewTarget then
            DebugLog("Target: " .. NewTarget.Name)
            TargetRespawnConnection = NewTarget.CharacterAdded:Connect(function(newChar)
                if Toggles.SpawnCamp and Toggles.SpawnCamp.Value then
                     task.spawn(function()
                         -- Record Respawn Time
                         State.T_Respawn = os.clock()
                         local respawnTime = State.T_Respawn - State.T_Death
                         pcall(function() appendfile("active_bagger_logs.txt", string.format("[STATS] 🔄 Respawn Time: %.2fs\n", respawnTime)) end)
                         
                         DebugLog("SPAWN DETECTED - PRE-FIRING")
                         
                         -- BLIND PRE-FIRE: Start activation network calls BEFORE we even have the root
                         -- This relies on the server accepting the tool activation slightly early
                         task.spawn(function()
                             for i = 1, 10 do
                                 UseBag() -- Spam click
                                 task.wait(0.05)
                             end
                         end)

                         -- PREDICTION TP: Wait for Root via ChildAdded (Faster than WaitForChild)
                         local root = newChar:FindFirstChild("HumanoidRootPart")
                         if not root then
                             -- Hook ChildAdded for instant reaction
                             local conn
                             conn = newChar.ChildAdded:Connect(function(child)
                                 if child.Name == "HumanoidRootPart" then
                                     root = child
                                     if conn then conn:Disconnect() end
                                 end
                             end)
                             
                             -- Fallback wait if hook fails or slow
                             if not root then root = newChar:WaitForChild("HumanoidRootPart", 5) end
                         end
                         
                         if root and State.Target == NewTarget then
                             local glue = GetBagPosition(root)
                             api:set_desync_cframe(glue)
                             DebugLog("ROOT FOUND - INSTANT TP")
                         end
                     end)
                end
            end)
        end
    end

    
    
    -- Process target
    if State.Target and (IsTargetValid(State.Target) or IsDead(State.Target)) then
        State.T_StartBag = os.clock()
        local currentTime = tick()
        
        -- Update knocked status
        local isKnocked = IsKnocked(State.Target)
        local isDead = IsDead(State.Target)
        
        if (isKnocked or isDead) and State.T_Vulnerable == 0 then
             State.T_Vulnerable = currentTime
        elseif not (isKnocked or isDead) then
             State.T_Vulnerable = 0
        end
        
        State.IsKnocked = isKnocked
        
        -- Update bag status (Optimized frequency: Check EVERY FRAME if critical, or throttle slightly)
        -- Removing arbitrary 0.15s delay for instant registering
        local wasBagged = State.IsBagged
        State.IsBagged = IsBagged(State.Target)
        State.LastBagCheck = currentTime
        
        if not wasBagged and State.IsBagged then
            State.LastBagSuccess = currentTime
            State.StrategyFailCount = 0
            State.WasJustBagged = true
            State.T_BagStart = os.clock() -- [Debug Start]
            DebugLog("Bagged!")
            
            -- INSTANT RESTOCK: Buy a new bag IMMEDIATELY while they are in the bag
            if Toggles.SpawnCamp and Toggles.SpawnCamp.Value then
                task.spawn(function()
                    TriggerBuyBag()
                end)
            end
            
            if Toggles.DeepDebug and Toggles.DeepDebug.Value then
                local t_now = os.clock()
                
                -- Use Vulnerable time for reaction if available, else Detect time (fallback)
                local t_base = (State.T_Vulnerable > 0) and State.T_Vulnerable or State.T_Detect
                
                local r_react = State.T_StartBag - t_base
                local r_input = State.T_Click - State.T_Equip
                local r_ping = t_now - State.T_Click
                local r_total = t_now - t_base
                
                local report = string.format(
                    "\n[BAGGER DEBUG] ⏱️ TIMING REPORT for %s\n" ..
                    "------------------------------------------------\n" ..
                    "> Knocked to Action: %.4fs (Reaction)\n" ..
                    "> Equip to Click:    %.4fs\n" ..
                    "> Click to Server:   %.4fs (Est Ping)\n" ..
                    "> TOTAL SEQUENCE:    %.4fs\n" ..
                    "------------------------------------------------",
                    State.Target.Name, math.max(0, r_react), math.max(0, r_input), math.max(0, r_ping), math.max(0, r_total)
                )
                
                -- Log to file instead of console
                pcall(function()
                    appendfile("active_bagger_logs.txt", report .. "\n")
                end)
                
                api:notify("Timing Report Saved to File", 3)
            end
        end
        
        if wasBagged and not State.IsBagged then
            State.BagRemovedTime = currentTime
            DebugLog("Bag removed - preparing pre-fire")
            
            if Toggles.DeepDebug and Toggles.DeepDebug.Value and State.T_BagStart > 0 then
                 -- Only log duration if they didn't die (Escaped?)
                 if not IsDead(State.Target) then
                     local duration = os.clock() - State.T_BagStart
                     local logMsg = string.format("[BAGGER DEBUG] ⏳ Hold Duration: %.2fs\n", duration)
                     pcall(function()
                        appendfile("active_bagger_logs.txt", logMsg)
                     end)
                 end
            end
        end
        
        
        -- Check if we should void
        State.ShouldVoid = false
        

        local shouldKill = State.IsBagged and not State.BuyingBag
        local shouldStomp = State.IsKnocked and not State.IsBagged and (Toggles.AutoStomp and Toggles.AutoStomp.Value)
        local shouldPreFireBag = not State.IsBagged and not State.IsKnocked and ShouldStartBagging()
        local isDead = IsDead(State.Target)

        if isDead and Toggles.VoidWhenDead and Toggles.VoidWhenDead.Value then
                -- === DEAD VOID MODE ===
                if State.Mode ~= "void_dead" then
                    State.T_Death = os.clock() -- Died now
                    local timeToKill = State.T_Death - State.T_BagStart
                    if State.T_BagStart > 0 then
                        pcall(function() appendfile("active_bagger_logs.txt", string.format("[STATS] 💀 Kill Time: %.2fs\n", timeToKill)) end)
                    end
                    
                    State.Mode = "void_dead"
                    DebugLog("TARGET DEAD - VOIDING")
                end
                
                SetVoid(false) -- Disable safety void checks
                SetFlameMode(false)
                api:set_ragebot(false)
                UpdateTargetUI("Dead: " .. State.Target.Name)

                -- Continuously void while dead
                api:set_server_cframe(VoidCFrame)
                
                -- === SPAWN CAMP PRE-PREP ===
                if Toggles.SpawnCamp and Toggles.SpawnCamp.Value then
                     local Bag = GetBagTool()
                     if not Bag then
                         TriggerBuyBag()
                     elseif Bag.Parent ~= LocalPlayer.Character then
                         -- Pre-equip logic
                         local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                         if humanoid then
                             humanoid:EquipTool(Bag)
                             State.T_Equip = os.clock() -- Mark as equipped
                         end
                     end
                end

        elseif shouldStomp then

            -- === STOMP MODE ===
            if State.Mode ~= "stomping" then
                State.Mode = "stomping"
                DebugLog("STOMPING")
            end
            
            SetVoid(false)
            UpdateTargetUI(State.Target.Name)
            SetFlameMode(false)
            api:set_ragebot(true) -- Ragebot will handle stomping
            
        elseif shouldKill then
            -- === KILL MODE ===
            if State.Mode ~= "killing" then
                State.Mode = "killing"
                DebugLog("KILLING")
            end
            
            SetVoid(false)
            UpdateTargetUI(State.Target.Name)
            
            if Options.KillModeDropdown.Value == "Normal Ragebot" then
                SetFlameMode(false)
            else
                SetFlameMode(true)
            end
            
            api:set_ragebot(true)
            
        elseif shouldPreFireBag then
            -- === PRE-FIRE BAG MODE ===
            if State.Mode ~= "prefire_bagging" then
                State.Mode = "prefire_bagging"
                State.BagAttempts = 0
                DebugLog("PRE-FIRE BAGGING")
            end
            
            SetVoid(false)
            SetFlameMode(false)
            api:set_ragebot(false)
            UpdateTargetUI("nil")
            
            if not State.BuyingBag then
                UseBag()
            end
            
        else
            -- === NORMAL BAG MODE ===
            if State.Mode ~= "bagging" then
                State.Mode = "bagging"
                State.BagAttempts = 0
                DebugLog("BAGGING")
            end
            
            SetVoid(false)
            SetFlameMode(false)
            api:set_ragebot(false)
            UpdateTargetUI("nil")
            
            if not State.BuyingBag then
                UseBag()
                
                if currentTime - State.LastBagSuccess > 1 then
                    State.StrategyFailCount = State.StrategyFailCount + 1
                end
            end
        end
    else
        -- === IDLE MODE ===
        if State.Mode ~= "idle" then
            State.Mode = "idle"
            State.LastSetTarget = ""
            api:set_ragebot(false)
            SetFlameMode(false)
            SetVoid(false)
            State.WasJustBagged = false
            State.ShouldVoid = false
            State.IsKnocked = false
        end
    end
end))

-- ========== PHYSICS LOOP ==========
local PhysicsConnection = api:add_connection(RunService.Heartbeat:Connect(function()
    if not (Toggles.MasterSwitch and Toggles.MasterSwitch.Value) or not State.Target then 
        return 
    end
    
    if State.BuyingBag or State.ShouldVoid then
        return
    end
    
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
    
    local TargetChar = State.Target.Character
    if not TargetChar then return end
    local TargetRoot = TargetChar:FindFirstChild("HumanoidRootPart")
    
    if MyRoot and TargetRoot then
        -- If in kill or stomp mode, unglue
        if (State.IsBagged and State.Mode == "killing") or (State.IsKnocked and State.Mode == "stomping") then
            pcall(function()
                sethiddenproperty(MyRoot, "PhysicsRepRootPart", nil)
            end)
            return
        end
        
        -- If in bag mode or pre-fire mode, glue and position
        if State.Mode == "bagging" or State.Mode == "prefire_bagging" then
            pcall(function()
                sethiddenproperty(MyRoot, "PhysicsRepRootPart", TargetRoot)
            end)
            
            local GlueCFrame = GetBagPosition(TargetRoot)
            api:set_desync_cframe(GlueCFrame)
        end
    end
    
    -- Void Logic Application
    if State.Mode == "void_dead" then
         api:set_server_cframe(VoidCFrame)
    end
end))



-- ========== EVENT HANDLERS ==========
api:on_event("localplayer_died", function()
    State.Target = nil
    State.IsBagged = false
    State.IsKnocked = false
    State.BuyingBag = false
    State.Mode = "idle"
    State.CurrentStrategy = 1
    State.WasJustBagged = false
    State.ShouldVoid = false
end)

api:on_event("localplayer_spawned", function(character)
    State.BagAttempts = 0
    State.StrategyFailCount = 0
end)

api:on_event("unload", function()
    api:notify("Auto Bag Pro unloaded", 2)
    
    api:set_ragebot(false)
    SetFlameMode(false)
    SetVoid(false)
    State.BuyingBag = false
    
    if PhysicsConnection then
        pcall(function()
            PhysicsConnection:Disconnect()
        end)
    end
    
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            pcall(function()
                sethiddenproperty(root, "PhysicsRepRootPart", nil)
            end)
        end
    end
end)

api:notify("Auto Bag Pro loaded", 3)
