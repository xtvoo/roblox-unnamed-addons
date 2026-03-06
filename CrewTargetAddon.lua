api:set_lua_name("Crew Target Addon")

local Handler = loadstring(game:HttpGet("https://raw.githubusercontent.com/XK5NG/XK5NG.github.io/main/Handler"))()
local Players = Handler:CloneRef("Players")
local LocalPlayer = Players.LocalPlayer

-- ========== UI SETUP ==========
local Tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local Main = Tab:AddRightGroupbox("Crew Targeting")

-- Helper to format names exactly like the UI expects
local function GetPlayerFormat(player)
    return string.format("%s (@%s)", player.DisplayName, player.Name)
end

Main:AddButton("Add Target's Crew to Ragebot", function()
    -- 1. Get Current Target (Silent Aim)
    local target = api:get_target("silent")
    
    if not target then
        api:notify("No Silent Aim Target Found!", 3)
        return
    end
    
    -- 2. Validate Target Data
    -- Robust check for DataFolder structure
    local data = target:FindFirstChild("DataFolder")
    if not data then 
        print("[CrewAddon] Target has no DataFolder") 
        api:notify("Target has no Data", 3) 
        return 
    end
    
    local info = data:FindFirstChild("Information")
    if not info then 
        print("[CrewAddon] Target has no DataFolder.Information") 
        api:notify("Target has no Info", 3) 
        return 
    end
    
    local crewObj = info:FindFirstChild("Crew")
    if not crewObj then 
        print("[CrewAddon] Target has no DataFolder.Information.Crew") 
        api:notify("Target has no Crew Value", 3) 
        return 
    end
    
    local targetCrewID = tostring(crewObj.Value)
    local targetName = target.Name
    
    print("[CrewAddon] Target: " .. targetName .. " | CrewID: " .. targetCrewID)
    
    if targetCrewID == "0" or targetCrewID == "" then
        api:notify("Target is not in a Crew!", 3)
        return
    end
    
    -- 3. Find All Players in that Crew
    local crewMembers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pData = p:FindFirstChild("DataFolder")
            if pData then
                local pInfo = pData:FindFirstChild("Information")
                if pInfo then
                    local pCrew = pInfo:FindFirstChild("Crew")
                    if pCrew and tostring(pCrew.Value) == targetCrewID then
                        table.insert(crewMembers, p)
                        print("[CrewAddon] Match: " .. p.Name)
                    end
                end
            end
        end
    end
    
    if #crewMembers == 0 then
        api:notify("No other crew members found.", 3)
        return
    end
    
    -- 4. Update Ragebot Target List
    local UpdatedCount = 0
    local TargetsFound = false
    
    local function UpdateDropdown(uiName, uiObj)
        if not uiObj then return end
        TargetsFound = true
        print("[CrewAddon] Processing UI: " .. uiName)
        
        -- 1. Get/Update VALUES list (The available options)
        -- We must ensure the targets exist in the dropdown options first
        local currentValues = uiObj.Values or {} 
        -- LinoriaLib usually exposes .Values on the object
        
        local valuesChanged = false
        local valuesMap = {}
        for _, v in ipairs(currentValues) do valuesMap[v] = true end
        
        for _, member in ipairs(crewMembers) do
            local key = GetPlayerFormat(member)
            if not valuesMap[key] then
                table.insert(currentValues, key)
                valuesMap[key] = true
                valuesChanged = true
                print("[CrewAddon] Adding new option: " .. key)
            end
        end
        
        if valuesChanged then
            uiObj:SetValues(currentValues)
            print("[CrewAddon] Updated Values list for " .. uiName)
        end
        
        -- 2. Update SELECTION (Multi-Select: [Key] = true)
        local currentSelection = uiObj.Value
        local newSelection = {}
        
        -- Copy existing true values
        if type(currentSelection) == "table" then
            for k,v in pairs(currentSelection) do newSelection[k] = v end
        end
        
        local count = 0
        for _, member in ipairs(crewMembers) do
            local key = GetPlayerFormat(member)
            if not newSelection[key] then
                newSelection[key] = true
                count = count + 1
            end
        end
        
        if count > 0 then
            uiObj:SetValue(newSelection)
            UpdatedCount = math.max(UpdatedCount, count)
            print("[CrewAddon] Set new selection for " .. uiName)
        else
            print("[CrewAddon] No new targets selected for " .. uiName)
        end
    end
    
    -- Try API getter
    UpdateDropdown("TargetList (API)", api:get_ui_object("TargetList"))
    UpdateDropdown("ragebot_targets (API)", api:get_ui_object("ragebot_targets"))
    
    -- Try Global Options (Fallback if in same env)
    if not TargetsFound and _G.Options then
        UpdateDropdown("TargetList (Global)", _G.Options.TargetList)
        UpdateDropdown("ragebot_targets (Global)", _G.Options.ragebot_targets)
    end
    
    -- Try Options if implicitly available
    if not TargetsFound and Options then
         UpdateDropdown("TargetList (Local Options)", Options.TargetList)
    end
    
    if not TargetsFound then
        api:notify("Could not find TargetList UI Object!", 5)
        warn("[CrewAddon] CRITICAL: Failed to find UI Object 'TargetList'. Ensure Bagger script is running.")
    elseif UpdatedCount > 0 then
        api:notify("Added " .. UpdatedCount .. " crew members!", 4)
    else
        api:notify("Matches already in list.", 3)
    end
end)

Main:AddLabel("Use Silent Aim to lock a target first.")

api:notify("Crew Target Addon Loaded", 3)
