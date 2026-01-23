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

-- ========== STATE ==========
local State = {
    Target = nil,
    IsArresting = false,
    LastArrestTime = 0,
    Mode = "idle",
    ArrestAttempts = 0
}

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
    
    -- Get target from silent aim/aimbot
    local Target = api:get_target("silent") or api:get_target("aimbot")
    
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
            DebugLog("Target died before arrest")
            return
        end
        
        if isKnocked and not State.IsArresting then
            -- Target is knocked - arrest them!
            State.Mode = "arresting"
            State.IsArresting = true
            
            if Toggles.NotifyArrest and Toggles.NotifyArrest.Value then
                api:notify("🚔 Arresting " .. Target.Name .. " (" .. GetWantedLevel(Target) .. " wanted)", 2)
            end
            
            -- Disable ragebot
            api:set_ragebot(false)
            
            -- Perform arrest
            PerformArrest(Target)
        elseif not isKnocked then
            -- Kill target first
            State.Mode = "killing_for_arrest"
            api:set_ragebot(true)
            DebugLog("Killing target for arrest: " .. Target.Name)
        end
        
    elseif arrestMode == "Bag+Knock+Arrest" then
        -- MODE 2: Bag, knock, then arrest
        -- TODO: Integrate with bag system
        -- For now, use same logic as instant mode
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
