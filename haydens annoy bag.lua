api:set_lua_name("haydens annoy bag")

local Handler = loadstring(game:HttpGet("https://raw.githubusercontent.com/XK5NG/XK5NG.github.io/main/Handler"))()
local Players = Handler:CloneRef("Players")
local RunService = Handler:CloneRef("RunService")
local Workspace = Handler:CloneRef("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ========== UI SETUP ==========
local Tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local Main = Tab:AddLeftGroupbox("Annoy Bag - Main")
local Bagging = Tab:AddRightGroupbox("Annoy Bag - Config")

Main:AddToggle("MasterSwitch", { 
    Text = "Enable Annoy Bag", 
    Default = false,
    Tooltip = "Repeatedly bags the target to trap them." 
})

Bagging:AddDropdown("BagStrategy", {
    Values = {"Adaptive", "Behind", "Below", "Above", "Aggressive Spin"},
    Default = 1,
    Text = "Bag Position Strategy",
    Tooltip = "Adaptive tries multiple positions"
})

Bagging:AddSlider("BagSpamRate", { 
    Text = "Bag Spam Rate", 
    Default = 5, 
    Min = 1, 
    Max = 100, 
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

Bagging:AddSlider("BagAboveHeight", {
    Text = "Above Height",
    Default = 3,
    Min = 0,
    Max = 10,
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

-- ========== STATE ==========
local State = {
    Target = nil,
    IsBagged = false,
    LastSetTarget = "",
    BuyingBag = false,
    LastBuyTime = 0,
    BagAttempts = 0,
    LastBagCheck = 0,
    LastBagAttempt = 0,
    CurrentStrategy = 1,
    StrategyFailCount = 0,
    LastBagSuccess = 0,
    BagRemovedTime = 0,
    
    -- Timestamps
    T_Equip = 0,
    T_Click = 0,
}

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
    val = val:match("^%s*(.-)%s*$")
    if val == "" then return end
    
    local bestMatch = nil
    local bestScore = 0
    local lowerVal = val:lower()
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pName = p.Name:lower()
            local pDisplay = p.DisplayName:lower()
            local pFormatted = GetPlayerFormat(p):lower()
            local currentScore = 0
            
            if pName == lowerVal then currentScore = 3
            elseif pName:find("^" .. lowerVal, 1, false) then currentScore = 2
            elseif pName:find(lowerVal, 1, true) then currentScore = 1 end
            
            if pDisplay == lowerVal then currentScore = math.max(currentScore, 3)
            elseif pDisplay:find("^" .. lowerVal, 1, false) then currentScore = math.max(currentScore, 2)
            elseif pDisplay:find(lowerVal, 1, true) then currentScore = math.max(currentScore, 1) end
            
            if pFormatted:find(lowerVal, 1, true) then currentScore = math.max(currentScore, 1) end
            
            if currentScore > bestScore then
                bestMatch = p
                bestScore = currentScore
            elseif currentScore == bestScore and bestScore > 0 then
                if bestMatch and #p.Name < #bestMatch.Name then bestMatch = p end
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
        end
        Options.PlayerSearchInput:SetValue("")
    else
        api:notify("No player found matching: " .. val, 2)
        Options.PlayerSearchInput:SetValue("")
    end
end)

-- ========== BAG STRATEGIES ==========
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
        local offset = Vector3.new(math.cos(angle) * distance, -height, math.sin(angle) * distance)
        return CFrame.new(targetRoot.Position + offset, targetRoot.Position)
    end,
    function(targetRoot)
        local height = Options.BagAboveHeight and Options.BagAboveHeight.Value or 3
        local above = Vector3.new(0, height, 0)
        return CFrame.new(targetRoot.Position + above, targetRoot.Position)
    end,
}

-- ========== HELPER FUNCTIONS ==========
local function DebugLog(message)
    -- Simplified logging
    -- print("[AnnoyBag] " .. message)
end

local function GetBagTool()
    if not LocalPlayer.Character then return nil end
    local bag = LocalPlayer.Character:FindFirstChild("[BrownBag]")
    if not bag then bag = LocalPlayer.Backpack:FindFirstChild("[BrownBag]") end
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

local function IsTargetValid(player)
    if not player or not player.Character then return false end
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    if statusCache.Dead or statusCache.Grabbed then return false end
    local charCache = api:get_character_cache(player)
    if not charCache or not charCache.HumanoidRootPart then return false end
    return true
end

local function TriggerBuyBag()
    if api:can_desync() and not State.BuyingBag then
        local currentTime = tick()
        local rbStatus = api:get_ragebot_status()
        local ignoreCooldown = Toggles.SpawnCamp and Toggles.SpawnCamp.Value
        
        if rbStatus ~= "buying" and (ignoreCooldown or currentTime - State.LastBuyTime > 2) then
            State.BuyingBag = true
            State.LastBuyTime = currentTime
            task.spawn(function()
                DebugLog("Buying bag...")
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait()
                api:buy_item("brownbag", false, true)
                api:buy_item("brownbag", false, true)
                task.wait()
                vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.1)
                State.BuyingBag = false
            end)
        end
    end
end

local function UseBag()
    local currentTime = tick()
    local spamRate = Options.BagSpamRate and Options.BagSpamRate.Value or 5
    local spamDelay = 1 / spamRate
    
    if currentTime - State.LastBagAttempt < spamDelay then return false end
    
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
            task.spawn(function() Bag:Activate() end)
        end
    end
    
    if Bag.Parent == LocalPlayer.Character then
        if State.T_Equip == 0 then State.T_Equip = os.clock() end
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
            end
        end
        return BagStrategies[State.CurrentStrategy](targetRoot)
    elseif strategy == "Behind" then return BagStrategies[1](targetRoot)
    elseif strategy == "Below" then return BagStrategies[2](targetRoot)
    elseif strategy == "Above" then return BagStrategies[7](targetRoot)
    elseif strategy == "Aggressive Spin" then return BagStrategies[6](targetRoot)
    end
    return BagStrategies[1](targetRoot)
end

-- ========== MAIN LOGIC LOOP ==========
api:add_connection(RunService.Heartbeat:Connect(function(dt)
    if not (Toggles.MasterSwitch and Toggles.MasterSwitch.Value) then
        State.LastSetTarget = ""
        State.BuyingBag = false
        State.WasJustBagged = false
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
               sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
            end
        end)
        return
    end

    -- Pre-Buy
    if Toggles.SpawnCamp and Toggles.SpawnCamp.Value then
        if not GetBagTool() then TriggerBuyBag() end
    end
    
    -- Get Target
    local NewTarget = nil
    if Options.TargetList then
        local selected_entries = Options.TargetList.Value
        local specific_targets = {}
        for name_str, is_selected in pairs(selected_entries) do
            if is_selected then
                local username = name_str:match("@(.+)")
                if not username then username = name_str:match("%((.+)%)") end
                if username then
                    local p = Players:FindFirstChild(username)
                    if p then table.insert(specific_targets, p) end
                end
            end
        end
        
        if #specific_targets > 0 then
            local found_unbagged = nil
            local found_bagged_alive = nil
            for _, p in ipairs(specific_targets) do
                if IsTargetValid(p) then
                    if not IsBagged(p) then
                        found_unbagged = p
                        break
                    elseif not found_bagged_alive then
                        found_bagged_alive = p
                    end
                end
            end
            if found_unbagged then NewTarget = found_unbagged
            elseif found_bagged_alive then NewTarget = found_bagged_alive end
        end
    end
    
    if State.Target ~= NewTarget then
        State.Target = NewTarget
        State.StrategyFailCount = 0
        State.WasJustBagged = false
        
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
            end
        end)
        
        if TargetRespawnConnection then TargetRespawnConnection:Disconnect() TargetRespawnConnection = nil end
        
        if NewTarget then
            TargetRespawnConnection = NewTarget.CharacterAdded:Connect(function(newChar)
                if Toggles.SpawnCamp and Toggles.SpawnCamp.Value then
                    task.spawn(function()
                        for i = 1, 10 do UseBag() task.wait(0.05) end
                    end)
                end
            end)
        end
    end
    
    if State.Target then
        -- Check Bag Status
        local wasBagged = State.IsBagged
        State.IsBagged = IsBagged(State.Target)
        
        if not wasBagged and State.IsBagged then
            State.LastBagSuccess = tick()
            State.StrategyFailCount = 0
            if Toggles.SpawnCamp and Toggles.SpawnCamp.Value then
                task.spawn(TriggerBuyBag)
            end
        end
        
        -- ANNOY LOGIC
        if State.IsBagged then
            if not GetBagTool() and not State.BuyingBag then
                 TriggerBuyBag()
            end
        else
            -- Check integrity
            if State.Target and State.Target.Character and LocalPlayer.Character then
                 local targetRoot = State.Target.Character:FindFirstChild("HumanoidRootPart")
                 local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                 
                 if targetRoot and myRoot then
                     pcall(function()
                         local glueCFrame = GetBagPosition(targetRoot)
                         sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot)
                         if api:can_desync() then
                             api:set_desync_cframe(glueCFrame)
                         end
                     end)
                     UseBag()
                 end
            end
        end
    end
end))
