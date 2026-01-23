api:set_lua_name("auto_arrest")

local Handler = loadstring(game:HttpGet("https://raw.githubusercontent.com/XK5NG/XK5NG.github.io/main/Handler"))()
local Players = Handler:CloneRef("Players")
local RunService = Handler:CloneRef("RunService")
local Workspace = Handler:CloneRef("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ========== UI SETUP ==========
local Tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local Main = Tab:AddLeftGroupbox("Auto Arrest - Main")
local Settings = Tab:AddRightGroupbox("Auto Arrest - Settings")

Main:AddToggle("ArrestEnabled", { 
    Text = "Enable Auto Arrest", 
    Default = false,
    Tooltip = "Only works if you're police"
})

Main:AddDropdown("ArrestMode", {
    Values = {"Instant Kill+Arrest", "Bag+Knock+Arrest"},
    Default = 1,
    Text = "Arrest Mode",
    Tooltip = "Instant = Kill then arrest | Bag = Bag, knock, then arrest"
})

Main:AddDropdown("TargetType", {
    Values = {"Silent Aim", "Dropdown List", "Both"},
    Default = 1,
    Text = "Target Source",
    Tooltip = "Where to get targets from"
})

Main:AddSlider("MinWanted", {
    Text = "Min Wanted Level",
    Default = 100,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Suffix = " wanted",
    Tooltip = "Only arrest targets with this wanted level or higher"
})

Settings:AddSlider("ArrestOffsetX", {
    Text = "Arrest Offset X",
    Default = 0,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Compact = true
})

Settings:AddSlider("ArrestOffsetY", {
    Text = "Arrest Offset Y",
    Default = 2,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Compact = true
})

Settings:AddSlider("ArrestOffsetZ", {
    Text = "Arrest Offset Z",
    Default = 0,
    Min = -5,
    Max = 5,
    Rounding = 1,
    Compact = true
})

Settings:AddToggle("AutoEquipCuffs", {
    Text = "Auto Equip Cuffs",
    Default = true,
    Tooltip = "Automatically equip cuffs when arresting"
})

Settings:AddToggle("NotifyArrest", {
    Text = "Arrest Notifications",
    Default = true
})

Settings:AddToggle("DebugMode", {
    Text = "Debug Mode",
    Default = false
})

-- Multi-Target Dropdown
local PlayerDropdown = Main:AddDropdown("TargetList", {
    Values = {},
    Default = {},
    Multi = true,
    Text = "Select Targets",
    Tooltip = "Specific players to arrest"
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
    IsArresting = false,
    LastArrestTime = 0,
    Mode = "idle",
    ArrestAttempts = 0
}

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
            
            local currentScore = 0
            
            if pName == lowerVal then currentScore = 3
            elseif pName:find("^" .. lowerVal, 1, false) then currentScore = 2
            elseif pName:find(lowerVal, 1, true) then currentScore = 1
            end
            
            if pDisplay == lowerVal then currentScore = math.max(currentScore, 3)
            elseif pDisplay:find("^" .. lowerVal, 1, false) then currentScore = math.max(currentScore, 2)
            elseif pDisplay:find(lowerVal, 1, true) then currentScore = math.max(currentScore, 1)
            end
            
            if currentScore > bestScore then
                bestMatch = p
                bestScore = currentScore
            elseif currentScore == bestScore and bestScore > 0 then
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
            api:notify("Added " .. found.Name .. " to arrest targets!", 2)
        else
            api:notify(found.Name .. " is already selected.", 2)
        end
        
        Options.PlayerSearchInput:SetValue("")
    else
        api:notify("No player found matching: " .. val, 2)
        Options.PlayerSearchInput:SetValue("")
    end
end)

-- ========== HELPER FUNCTIONS ==========
local function DebugLog(message)
    if Toggles.DebugMode and Toggles.DebugMode.Value then
        print("[AUTO ARREST DEBUG] " .. message)
    end
end

local function IsPolice()
    -- Check if player is police
    local character = LocalPlayer.Character
    if not character then return false end
    
    -- Method 1: Check for police badge/uniform
    local policeCheck = character:FindFirstChild("PoliceShirt") or 
                       character:FindFirstChild("PolicePants") or
                       Workspace.Ignored["Join/Leave"]:FindFirstChild("ClickDetector")
    
    return policeCheck ~= nil
end

local function GetCuffs()
    if not LocalPlayer.Character then return nil end
    
    local cuffs = LocalPlayer.Character:FindFirstChild("Cuff")
    if not cuffs then
        cuffs = LocalPlayer.Backpack:FindFirstChild("Cuff")
    end
    
    return cuffs
end

local function EquipCuffs()
    if not Toggles.AutoEquipCuffs or not Toggles.AutoEquipCuffs.Value then return false end
    
    local cuffs = GetCuffs()
    if not cuffs then
        DebugLog("No cuffs found in backpack")
        return false
    end
    
    if cuffs.Parent == LocalPlayer.Backpack then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(cuffs)
            DebugLog("Equipped cuffs")
            return true
        end
    end
    
    return cuffs.Parent == LocalPlayer.Character
end

local function GetWantedLevel(player)
    -- Get player's wanted level from their overhead GUI or leaderstats
    if not player then return 0 end
    
    -- Method 1: Check leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local wanted = leaderstats:FindFirstChild("Wanted") or leaderstats:FindFirstChild("Bounty")
        if wanted and wanted.Value then
            return tonumber(wanted.Value) or 0
        end
    end
    
    -- Method 2: Check character overhead
    if player.Character then
        local head = player.Character:FindFirstChild("Head")
        if head then
            for _, gui in ipairs(head:GetChildren()) do
                if gui:IsA("BillboardGui") then
                    local wantedLabel = gui:FindFirstChildWhichIsA("TextLabel", true)
                    if wantedLabel and wantedLabel.Text:find("Wanted") then
                        local wantedNum = wantedLabel.Text:match("%d+")
                        if wantedNum then
                            return tonumber(wantedNum) or 0
                        end
                    end
                end
            end
        end
    end
    
    return 0
end

local function IsKnocked(player)
    if not player then return false end
    
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    
    return statusCache["K.O"] == true
end

local function IsDead(player)
    if not player then return false end
    
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    
    return statusCache.Dead == true
end

local function IsTargetValid(player)
    if not player or not player.Character then return false end
    
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    
    if statusCache.Dead or statusCache.Grabbed then
        return false
    end
    
    local charCache = api:get_character_cache(player)
    if not charCache or not charCache.HumanoidRootPart then return false end
    
    return true
end

local function CanArrestTarget(player)
    if not player then return false, "No target" end
    
    -- Check wanted level
    local wantedLevel = GetWantedLevel(player)
    local minWanted = Options.MinWanted and Options.MinWanted.Value or 100
    
    if wantedLevel < minWanted then
        return false, string.format("Low wanted (%d/%d)", wantedLevel, minWanted)
    end
    
    return true, "Can arrest"
end

-- ========== ARREST LOGIC ==========
local function PerformArrest(target)
    if not target or not target.Character then return false end
    
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    
    -- Get arrest offset
    local offsetX = Options.ArrestOffsetX and Options.ArrestOffsetX.Value or 0
    local offsetY = Options.ArrestOffsetY and Options.ArrestOffsetY.Value or 2
    local offsetZ = Options.ArrestOffsetZ and Options.ArrestOffsetZ.Value or 0
    local offset = Vector3.new(offsetX, offsetY, offsetZ)
    
    -- Stick to target using PhysicsRepRootPart
    pcall(function()
        sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot)
    end)
    
    -- Position above target for arrest
    local arrestCFrame = CFrame.new(targetRoot.Position + offset)
    api:set_desync_cframe(arrestCFrame)
    
    -- Equip cuffs
    if EquipCuffs() then
        -- Arrest by activating the cuff tool (Da Hood uses client-side arrest)
        task.wait(0.1)
        local cuffs = GetCuffs()
        if cuffs and cuffs.Parent == LocalPlayer.Character then
            cuffs:Activate()
            DebugLog("Activated cuffs on " .. target.Name)
            State.ArrestAttempts = State.ArrestAttempts + 1
        end
        
        return true
    end
    
    return false
end

-- ========== MAIN LOGIC ==========
api:add_connection(RunService.Heartbeat:Connect(function()
    if not (Toggles.ArrestEnabled and Toggles.ArrestEnabled.Value) then
        if State.Mode ~= "idle" then
            State.Mode = "idle"
            State.Target = nil
            State.IsArresting = false
            
            -- Unglue
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
                end)
            end
        end
        return
    end
    
    -- Check if we're police
    if not IsPolice() then
        if Toggles.NotifyArrest and Toggles.NotifyArrest.Value and State.Mode ~= "not_police" then
            api:notify("❌ Not police! Cannot arrest.", 3)
            State.Mode = "not_police"
        end
        return
    end
    
    -- Get target based on target type
    local targetType = Options.TargetType and Options.TargetType.Value or "Silent Aim"
    local Target = nil
    
    if targetType == "Silent Aim" then
        -- Only use silent aim/aimbot
        Target = api:get_target("silent") or api:get_target("aimbot")
        
    elseif targetType == "Dropdown List" then
        -- Only use dropdown targets
        if Options.TargetList then
            local selected_entries = Options.TargetList.Value
            
            for name_str, is_selected in pairs(selected_entries) do
                if is_selected then
                    local username = name_str:match("@(.+)")
                    if username then
                        username = username:gsub("%)", "")
                        local p = Players:FindFirstChild(username)
                        if p and IsTargetValid(p) then
                            Target = p
                            break
                        end
                    end
                end
            end
        end
        
    elseif targetType == "Both" then
        -- Try dropdown first, then silent aim
        if Options.TargetList then
            local selected_entries = Options.TargetList.Value
            
            for name_str, is_selected in pairs(selected_entries) do
                if is_selected then
                    local username = name_str:match("@(.+)")
                    if username then
                        username = username:gsub("%)", "")
                        local p = Players:FindFirstChild(username)
                        if p and IsTargetValid(p) then
                            Target = p
                            break
                        end
                    end
                end
            end
        end
        
        -- Fallback to silent aim
        if not Target then
            Target = api:get_target("silent") or api:get_target("aimbot")
        end
    end
    
    if not Target then
        State.Target = nil
        State.IsArresting = false
        return
    end
    
    -- Check if target changed
    if State.Target ~= Target then
        State.Target = Target
        State.ArrestAttempts = 0
        State.IsArresting = false
        DebugLog("New target: " .. Target.Name)
    end
    
    -- Check if we can arrest this target
    local canArrest, reason = CanArrestTarget(Target)
    if not canArrest then
        if Toggles.NotifyArrest and Toggles.NotifyArrest.Value then
            api:notify("⚠️ " .. Target.Name .. ": " .. reason .. " - Killing normally", 2)
        end
        
        -- Kill them normally with ragebot
        api:set_ragebot(true)
        State.Mode = "killing_low_wanted"
        return
    end
    
    -- Target has enough wanted - proceed with arrest
    local arrestMode = Options.ArrestMode and Options.ArrestMode.Value or "Instant Kill+Arrest"
    
    if arrestMode == "Instant Kill+Arrest" then
        -- MODE 1: Kill then arrest
        local isKnocked = IsKnocked(Target)
        local isDead = IsDead(Target)
        
        if isDead then
            State.Mode = "idle"
            State.IsArresting = false
            State.KnockedTime = 0
            DebugLog("Target died before arrest")
            return
        end
        
        if isKnocked and not State.IsArresting then
            -- Target is knocked - arrest them immediately!
            State.Mode = "arresting"
            State.IsArresting = true
            
            if Toggles.NotifyArrest and Toggles.NotifyArrest.Value then
                api:notify("🚔 Arresting " .. Target.Name .. " (" .. GetWantedLevel(Target) .. " wanted)", 2)
            end
            
            api:set_ragebot(false)
            PerformArrest(Target)
        elseif not isKnocked then
            -- Kill target first
            State.Mode = "killing_for_arrest"
            api:set_ragebot(true)
            DebugLog("Killing target for arrest: " .. Target.Name)
        end
        
    elseif arrestMode == "Bag+Knock+Arrest" then
        -- MODE 2: Bag, knock, then arrest
        -- TODO: Integrate with bag system for full bag+knock+arrest combo
        local isKnocked = IsKnocked(Target)
        
        if isKnocked and not State.IsArresting then
            State.Mode = "arresting"
            State.IsArresting = true
            
            if Toggles.NotifyArrest and Toggles.NotifyArrest.Value then
                api:notify("🚔 Arresting (Bag Mode) " .. Target.Name, 2)
            end
            
            api:set_ragebot(false)
            PerformArrest(Target)
        else
            -- Use ragebot to knock them
            State.Mode = "knocking_for_arrest"
            api:set_ragebot(true)
        end
    end
end))

-- ========== EVENTS ==========
api:on_event("localplayer_died", function()
    State.Target = nil
    State.IsArresting = false
    State.Mode = "idle"
end)

api:on_event("unload", function()
    api:notify("Auto Arrest unloaded", 2)
    api:set_ragebot(false)
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
        end)
    end
end)

api:notify("Auto Arrest loaded! (Police only)", 3)
