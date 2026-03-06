-- Whitelist Research & Debug Script
-- Purpose: Find a reliable way to whitelist friends and specific players programmatically.

api:set_lua_name("Whitelist_Research")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function safe_print(...)
    print("[WL DEBUG]", ...)
    api:notify("[WL DEBUG] Check Console (F9)", 3)
end

-- 1. Helper: Friend Detection
local function getFriends()
    local friends = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
             local isFriend = false
             pcall(function() isFriend = LocalPlayer:IsFriendsWith(p.UserId) end)
             if isFriend then
                 table.insert(friends, p)
             end
        end
    end
    return friends
end

-- 2. Helper: Crew Detection (Manual DataFolder check)
local function getCrewMembers()
    local crewmates = {}
    local myData = LocalPlayer:FindFirstChild("DataFolder")
    local myCrewVal = myData and myData:FindFirstChild("Information") and myData.Information:FindFirstChild("Crew")
    
    if myCrewVal and myCrewVal.Value ~= "" then
        local myCrewId = myCrewVal.Value
        safe_print("My Crew ID:", myCrewId)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local theirData = p:FindFirstChild("DataFolder")
                local theirCrew = theirData and theirData:FindFirstChild("Information") and theirData.Information:FindFirstChild("Crew")
                if theirCrew and theirCrew.Value == myCrewId then
                    table.insert(crewmates, p)
                end
            end
        end
    end
    return crewmates
end

-- 3. Research: List Native API Whitelist Types
local function dumpWhitelistUI()
    local wl = api:get_ui_object("ragebot_whitelist")
    if not wl then 
        safe_print("ERROR: 'ragebot_whitelist' UI object not found!")
        -- Try variations found in other scripts
        wl = api:get_ui_object("whitelist") or api:get_ui_object("Whitelist")
    end
    
    if wl then
        safe_print("Found Whitelist Object:", wl)
        safe_print("Current Value Type:", type(wl.Value))
        safe_print("Current Value:", game:GetService("HttpService"):JSONEncode(wl.Value or {}))
        
        -- Check if it supports options
        if wl.Options or wl.Values then
            safe_print("Available Options:", # (wl.Options or wl.Values or {}))
        end
    else
        safe_print("Critical: No whitelist UI object found.")
    end
    
    return wl
end

-- 4. Test: Try to set the whitelist
local function setWhitelist(players)
    local wl_obj = api:get_ui_object("ragebot_whitelist")
    if not wl_obj then return end
    
    -- Format: Unnamed API usually expects specific string formats like "DisplayName (@Username)" for dropdowns
    -- We need to check what is currently in the Options to match it.
    
    local new_val = {}
    -- If it's a multiselect dropdown (likely table)
    local current_options = wl_obj.Options or wl_obj.Values or {}
    
    for _, p in ipairs(players) do
        local fmt1 = p.Name
        local fmt2 = string.format("%s (@%s)", p.DisplayName, p.Name)
        
        -- Try to match existing options first
        local matched = false
        for _, opt in ipairs(current_options) do
            if opt == fmt1 or opt == fmt2 then
                if type(wl_obj.Value) == "table" then
                     -- Check if dictionary or array style
                     
                     -- Assumption 1: Dictionary { ["Name"] = true }
                     new_val[opt] = true
                     matched = true
                else
                     -- Assumption 2: Array { "Name" }
                     table.insert(new_val, opt)
                     matched = true
                end
            end
        end
        
        if not matched then
            safe_print("Warning: Player " .. p.Name .. " not found in dropdown options. Trying to force add...")
            -- Some UIs allow setting values not in options, or we might need to update options first
            if wl_obj.SetValues then
                table.insert(current_options, fmt2)
                wl_obj:SetValues(current_options)
                new_val[fmt2] = true -- Assume dict for multiselect often
            end
        end
    end
    
    safe_print("Attempting to set whitelist to:", game:GetService("HttpService"):JSONEncode(new_val))
    wl_obj:SetValue(new_val)
end


-- Main Run
task.spawn(function()
    safe_print("--- Starting Whitelist Research ---")
    
    -- Friends
    local friends = getFriends()
    safe_print("Friends Found:", #friends)
    for _, f in ipairs(friends) do safe_print(" - Friend:", f.Name) end
    
    -- Crew
    local crew = getCrewMembers()
    safe_print("Crew Found:", #crew)
    for _, c in ipairs(crew) do safe_print(" - Crew:", c.Name) end
    
    -- UI Dump
    local wl_ui = dumpWhitelistUI()
    
    -- Test: Autowhitelist friends
    if #friends > 0 then
        safe_print("Attempting to whitelist friends...")
        setWhitelist(friends)
    else
        safe_print("No friends to test whitelist with. Try adding someone.")
    end
    
    safe_print("--- Research Complete ---")
end)
