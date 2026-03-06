-- Attempt to locate the API table
local api = rawget(getfenv(), "api") or _G.api or shared.api

if not api and getgenv then
    api = getgenv().api
end

if not api then
    warn("[CrewTargeter] CRITICAL: Could not locate 'api' table.")
    return
end

local Tab = api:GetTab("ragebot") 
if not Tab then
   Tab = api:AddTab("ragebot")
end

local Group = Tab:AddLeftGroupbox("Crew Targeter")

-- Helper functions based on bot.txt analysis
local function GetOption(flag)
    return api:get_ui_object(flag)
end

local function SetOption(flag, value)
    local obj = GetOption(flag)
    if obj then
        if obj.SetValue then
            obj:SetValue(value)
        else
            obj.Value = value
        end
        return true
    end
    print("[CrewTargeter] Failed to find UI object:", flag)
    return false
end

local function GetValue(flag)
    local obj = GetOption(flag)
    return obj and obj.Value or nil
end

local function TargetCrew()
    local silentTarget = api:get_target("silent")
    
    if not silentTarget then
        api:notify("No Silent Aim target selected!", 3)
        return
    end

    print("[CrewTargeter] Target found:", silentTarget.Name)

    local crewValue = nil
    local success, result = pcall(function()
        return silentTarget.DataFolder.Information.Crew.Value
    end)
    
    if success then crewValue = result end

    print("[CrewTargeter] Crew Value:", crewValue)

    if not crewValue or crewValue == "" or crewValue == 0 then 
         api:notify("Target has no crew!", 3)
         return
    end

    local Players = game:GetService("Players")
    -- We will build a table compatible with Linoria Lib Multi-Dropdowns: { [Name] = true }
    -- And also keep a list for debug printing
    local newTargetsMap = {} 
    
    -- Try to find the Linoria Lib 'Options' table globally
    local Options = getgenv().Options
    if not Options then
        warn("[CrewTargeter] 'Options' global not found, falling back to api:get_ui_object")
    end

    local function SafeSetOption(flag, value)
        if Options and Options[flag] then
            -- Check if it's a dropdown and print info
            local opt = Options[flag]
            print("[CrewTargeter] Option found:", flag, "Type:", opt.Type, "ValueType:", type(opt.Value))
            
            -- If it's a Multi dropdown, it likely expects { [str] = true }
            -- If we are passing a single string to a multi, most libs handle it, but for multiple we need the table.
            return opt:SetValue(value)
        else
            return SetOption(flag, value)
        end
    end
    
    local function SafeGetValue(flag)
         if Options and Options[flag] then
            return Options[flag].Value
         end
         return GetValue(flag)
    end
    
    -- Preserve existing targets
    local existing = SafeGetValue("ragebot_targets")
    print("[CrewTargeter] Existing targets type:", type(existing))
    
    if type(existing) == "table" then
        for k, v in pairs(existing) do
            -- If it's { "A", "B" }
            if type(k) == "number" then
                newTargetsMap[v] = true
            -- If it's { ["A"] = true }
            else
                newTargetsMap[k] = v
            end
        end
    elseif type(existing) == "string" and existing ~= "" and existing ~= "nil" then
         newTargetsMap[existing] = true
    end

    -- Add the silent target themselves (User request: "add them as well")
    if silentTarget and silentTarget.Name then
        newTargetsMap[silentTarget.Name] = true
        print("[CrewTargeter] Adding silent target:", silentTarget.Name)
    end

    local count = 0
    local debugNames = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player ~= silentTarget then
            local pCrew = nil
            local s, r = pcall(function()
                return player.DataFolder.Information.Crew.Value
            end)
            if s then pCrew = r end
            
            if pCrew == crewValue then
                if not newTargetsMap[player.Name] then
                    newTargetsMap[player.Name] = true
                    count = count + 1
                    table.insert(debugNames, player.Name)
                    print("[CrewTargeter] Found crewmate:", player.Name)
                end
            end
        end
    end

    if count > 0 then
        print("[CrewTargeter] Setting targets:", table.concat(debugNames, ", "))
        
        -- Enable "Use Selected"
        SafeSetOption("ragebot_use_selected", true)
        
        -- Set targets using the MAP (Dictionary)
        local setSuccess = SafeSetOption("ragebot_targets", newTargetsMap)
        if not setSuccess then
             api:notify("Failed to update targets! Check console.", 3)
             return
        end
        
        -- Force update whitelist if needed (some scripts use separate whitelist)
        SafeSetOption("ragebot_whitelist", newTargetsMap)

        local Keybind = api:get_ui_object("ragebot_keybind")
        if Keybind and Keybind.OverrideState then
             Keybind:OverrideState(true)
        end
        
        if api.set_ragebot then
            api:set_ragebot(true)
        end

        api:notify("Added " .. tostring(count) .. " crew members!", 5)
    else
        api:notify("No other crew members found.", 3)
    end
end

Group:AddButton("Target Crew", TargetCrew)
