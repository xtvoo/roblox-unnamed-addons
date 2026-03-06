-- Auto Whitelist Addon
-- Automatically whitelists friends and crew members to prevent friendly fire.

api:set_lua_name("Auto_Whitelist")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WHITELIST_UI_ID = "ragebot_whitelist"
local script_keybind = Enum.KeyCode.U -- Default

-- UI Setup
local tab = api:GetTab("Whitelist Addon") or api:AddTab("Whitelist Addon")
local main_group = tab:AddLeftGroupbox("Auto Whitelist Settings")
local manual_group = tab:AddRightGroupbox("Manual Control")

-- UI Elements
local toggle_friends = main_group:AddToggle("wl_auto_friends", { Text = "Auto Whitelist Friends", Default = true })
local toggle_visuals = main_group:AddToggle("wl_visuals", { Text = "Visual Whitelist Confirmation", Default = true })

-- Visual Confirmation Logic (ESP style highlight)
local HighlightContainer = Instance.new("Folder")
HighlightContainer.Name = "WhitelistHighlights"
HighlightContainer.Parent = game:GetService("CoreGui")

local function updateVisuals(whitelisted_players)
    HighlightContainer:ClearAllChildren()
    
    if not toggle_visuals.Value then return end
    
    for p, _ in pairs(whitelisted_players) do
        if p.Character then
            local hl = Instance.new("Highlight")
            hl.Name = p.Name
            hl.Adornee = p.Character
            hl.FillColor = Color3.fromRGB(0, 255, 0) -- Green for safe
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.8
            hl.OutlineTransparency = 0.2
            hl.Parent = HighlightContainer
            
            -- Add BillboardGui for text
            local bg = Instance.new("BillboardGui")
            bg.Adornee = p.Character:FindFirstChild("Head")
            bg.Size = UDim2.new(0, 100, 0, 50)
            bg.StudsOffset = Vector3.new(0, 3, 0)
            bg.AlwaysOnTop = true
            bg.Parent = HighlightContainer
            
            local tl = Instance.new("TextLabel")
            tl.BackgroundTransparency = 1
            tl.Size = UDim2.new(1,0,1,0)
            tl.Text = "WHITELISTED"
            tl.TextColor3 = Color3.fromRGB(0, 255, 0)
            tl.TextStrokeTransparency = 0
            tl.Font = Enum.Font.Bold
            tl.TextSize = 14
            tl.Parent = bg
        end
    end
end

-- Manual Input
local input_username = manual_group:AddInput("wl_manual_input", {
    Default = "",
    Numeric = false,
    Finished = false,
    Text = "Username / Display Name",
    Tooltip = "Enter partial or full name",
    Placeholder = "Player Name...",
})

manual_group:AddButton("Whitelist Player", function()
    local name = input_username.Value
    if name and name ~= "" then
        -- Logic from chat command
        local target = Players:FindFirstChild(name)
        if not target then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():match(name:lower()) or p.DisplayName:lower():match(name:lower()) then
                    target = p
                    break
                end
            end
        end
        
        if target then
            -- We need to call a function to add them. 
            -- I'll expose the addToUI logic globally or move it up scope in a later tool call, 
            -- for now let's reuse the updateWhitelist logic which handles friends/crew, 
            -- but for manual we need specific logic.
            -- Actually, simpler: Fire the chat command logic directly or replicate it.
            
            -- Replicating manual add logic here for simplicity within the callback
             local fmt = string.format("%s (@%s)", target.DisplayName, target.Name)
             local function addToUI(ui_id)
                local wl_obj = api:get_ui_object(ui_id)
                if not wl_obj then return end
                
                local current_opts = wl_obj.Options or wl_obj.Values or {}
                local current_vals = wl_obj.Value or {}
                
                -- Deep copy
                local new_opts = {}
                local new_vals = {}
                if type(current_opts) == "table" then for k,v in pairs(current_opts) do new_opts[k] = v end end
                if type(current_vals) == "table" then for k,v in pairs(current_vals) do new_vals[k] = v end end
                
                -- Opts
                local found = false
                for _, v in pairs(new_opts) do if v == fmt then found = true break end end
                if not found then table.insert(new_opts, fmt) end
                if wl_obj.SetValues then wl_obj:SetValues(new_opts) end
                
                -- Vals
                 if (type(new_vals) == "table" and next(new_vals) ~= nil and type(next(new_vals)) == "string") then
                     new_vals[fmt] = true
                 else
                     local has = false
                     for _, v in ipairs(new_vals) do if v == fmt then has = true break end end
                     if not has then table.insert(new_vals, fmt) end
                 end
                 wl_obj:SetValue(new_vals)
            end
            
            addToUI(WHITELIST_UI_ID)
            addToUI("protector_whitelist")
            api:notify("Manually Whitelisted: " .. target.DisplayName, 3)
        else
            api:notify("Player not found.", 3)
        end
    end
end)


local function safe_call(func, name)
    local success, err = pcall(func)
    if not success then
        warn("[AutoWhitelist] Error in " .. (name or "unknown") .. ": " .. tostring(err))
    end
end

-- Formatting helper for UI library
local function getFormattedName(player)
    -- Debug logs confirm format is {"Username": true}
    return player.Name
end

-- Helper: Deep Copy to avoid readonly errors
local function cloneTable(t)
    if type(t) ~= "table" then return t end
    local new = {}
    for k, v in pairs(t) do
        new[k] = cloneTable(v)
    end
    return new
end

-- Core Logic: Sync Friends/Crew to UI
local function updateWhitelist()
    safe_call(function()
        local whitelist_obj = api:get_ui_object(WHITELIST_UI_ID) or api:get_ui_object("whitelist")
        if not whitelist_obj then return end
        
        local friends_and_crew = {}
        
        -- 1. Scan Friends (Check Toggle)
        if toggle_friends.Value then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local isFriend = false
                    pcall(function() isFriend = LocalPlayer:IsFriendsWith(p.UserId) end)
                    if isFriend then
                        friends_and_crew[p] = true
                    end
                end
            end
        end
        
        -- 2. Scan Crew (Check Toggle)
        if toggle_crew.Value then
            local myData = LocalPlayer:FindFirstChild("DataFolder")
            local myCrewVal = myData and myData:FindFirstChild("Information") and myData.Information:FindFirstChild("Crew")
            if myCrewVal and myCrewVal.Value ~= "" then
                 local myCrewId = myCrewVal.Value
                 for _, p in ipairs(Players:GetPlayers()) do
                     if p ~= LocalPlayer and not friends_and_crew[p] then
                         local theirData = p:FindFirstChild("DataFolder")
                         local theirCrew = theirData and theirData:FindFirstChild("Information") and theirData.Information:FindFirstChild("Crew")
                         if theirCrew and theirCrew.Value == myCrewId then
                             friends_and_crew[p] = true
                         end
                     end
                 end
            end
        end
        
        -- 3. Update UI
        local raw_selection = whitelist_obj.Value
        local raw_options = whitelist_obj.Options or whitelist_obj.Values
        
        local current_selection = cloneTable(raw_selection) or {}
        local current_options = cloneTable(raw_options) or {}
        
        local changed_sel = false
        local changed_opt = false
        
        local is_dict_options = (type(current_options) == "table" and next(current_options) ~= nil and type(next(current_options)) == "string")
        local is_dict_selection = (type(current_selection) == "table" and next(current_selection) ~= nil and type(next(current_selection)) == "string")

        for p, _ in pairs(friends_and_crew) do
            local fmt = getFormattedName(p)
            
            -- Update Options
            local has_opt = false
            for k, v in pairs(current_options) do
                if (type(k) == "number" and v == fmt) or (is_dict_options and k == fmt) then 
                    has_opt = true 
                    break 
                end
            end
            
            if not has_opt then
                if is_dict_options then
                    current_options[fmt] = true
                else
                    table.insert(current_options, fmt)
                end
                changed_opt = true
            end
            
            -- Update Selection
            if is_dict_selection then
                if not current_selection[fmt] then
                    current_selection[fmt] = true
                    changed_sel = true
                end
            else
                local has_sel = false
                for _, sel in ipairs(current_selection) do
                    if sel == fmt then has_sel = true break end
                end
                if not has_sel then
                    table.insert(current_selection, fmt)
                    changed_sel = true
                end
            end
        end
        
        if changed_opt then
            if whitelist_obj.SetValues then
                whitelist_obj:SetValues(current_options)
            elseif whitelist_obj.SetOptions then
                whitelist_obj:SetOptions(current_options)
            end
        end
        
        if changed_sel then
            whitelist_obj:SetValue(current_selection)
            api:notify("[AutoWhitelist] Added " .. tostring(table_count(friends_and_crew)) .. " allies.", 3)
        end
        
        -- Update Visuals
        updateVisuals(friends_and_crew)
        
    end, "updateWhitelist")
end

-- Helper for table count
local function table_count(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

-- Keybind Logic: Whitelist silent aim target
local UserInputService = game:GetService("UserInputService")
-- Poll for keybind press instead of direct generic connection, utilizing the Library's state if possible, 
-- or stick to standard InputBegan checking against the bind's value.
-- Standard Unnamed API keypickers often return KeyCode or a State.
-- Since documentation is sparse, we'll check the Value of the keypicker object during InputBegan.

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Check if the input matches our keybind
    -- bind_whitelist.Value usually holds the Enum.KeyCode or string representation
    local bindVal = bind_whitelist.Value
    local keyPressed = input.KeyCode
    
    -- Simple match check (handle string or Enum)
    local isMatch = false
    if typeof(bindVal) == "EnumItem" and bindVal == keyPressed then isMatch = true 
    elseif type(bindVal) == "string" and (Enum.KeyCode[bindVal] == keyPressed or bindVal == keyPressed.Name) then isMatch = true
    elseif bindVal == nil and keyPressed == Enum.KeyCode.U then isMatch = true -- Fallback default
    end
    
    if isMatch then
        -- Get Silent Aim Target
        local success, target_cache = pcall(function() return api:get_target_cache("silent") end)
        
        local target = nil
        if success and target_cache and target_cache.player then
            target = target_cache.player
        end
        
        if not target then
            local mouse = LocalPlayer:GetMouse()
            if mouse.Target and mouse.Target.Parent then
                target = Players:GetPlayerFromCharacter(mouse.Target.Parent)
            end
        end
        
        if target then
            api:notify("Whitelisting target: " .. target.DisplayName, 2)
            
            local fmt = getFormattedName(target)
            
            local function addToUI(ui_id)
                local wl_obj = api:get_ui_object(ui_id)
                if not wl_obj then return end
                
                local current_opts = wl_obj.Options or wl_obj.Values or {}
                local current_vals = wl_obj.Value or {}
                
                local new_opts = cloneTable(current_opts) or {}
                local new_vals = cloneTable(current_vals) or {}
                
                -- Options
                local has_opt = false
                for _, v in pairs(new_opts) do if v == fmt then has_opt = true break end end
                if not has_opt then table.insert(new_opts, fmt) end
                
                if wl_obj.SetValues then wl_obj:SetValues(new_opts) end
                
                -- Selection
                if (type(new_vals) == "table" and next(new_vals) ~= nil and type(next(new_vals)) == "string") then
                     new_vals[fmt] = true
                else
                     local has = false
                     for _, v in ipairs(new_vals) do if v == fmt then has = true break end end
                     if not has then table.insert(new_vals, fmt) end
                end
                 
                 wl_obj:SetValue(new_vals)
            end
            
            addToUI(WHITELIST_UI_ID) 
            addToUI("protector_whitelist")
            addToUI("whitelist")
        else
            api:notify("No target found to whitelist.", 2)
        end
    end
end)

-- Connections

-- Chat Commands
api:on_command("/wl", function(msg, args)
    if #args > 0 then
        local targetName = args[1]
        local target = Players:FindFirstChild(targetName)
        
        -- Fuzzy search if not found
        if not target then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():match(targetName:lower()) or p.DisplayName:lower():match(targetName:lower()) then
                    target = p
                    break
                end
            end
        end
        
        if target then
            updateWhitelist() -- Ensure sync first
            local wl_obj = api:get_ui_object(WHITELIST_UI_ID) or api:get_ui_object("whitelist")
            if wl_obj then
                local current_opts = wl_obj.Options or wl_obj.Values
                 -- Deep copy to modify
                local new_opts = {}
                if type(current_opts) == "table" then
                    for k,v in pairs(current_opts) do new_opts[k] = v end
                end
                
                local fmt = getFormattedName(target)
                local found = false
                for _, v in pairs(new_opts) do if v == fmt then found = true break end end
                
                if not found then table.insert(new_opts, fmt) end
                
                if wl_obj.SetValues then wl_obj:SetValues(new_opts) end
                
                local current_vals = wl_obj.Value
                local new_vals = {}
                if type(current_vals) == "table" then
                     for k,v in pairs(current_vals) do new_vals[k] = v end
                end
                
                -- Handle array vs dict
                if #new_vals > 0 or (next(new_vals) == nil) then
                     table.insert(new_vals, fmt)
                else
                     new_vals[fmt] = true
                end
                
                wl_obj:SetValue(new_vals)
                api:notify("Whitelisted " .. target.DisplayName, 3)
            end
        else
            api:notify("Player not found: " .. targetName, 3)
        end
    end
end)

api:on_command("/unwl", function(msg, args)
     -- Implementation for unwhitelist can be added similarly if needed
     api:notify("Unwhitelist command not fully implemented yet", 2)
end)

-- Initial Run
task.spawn(function()
    task.wait(1)
    updateWhitelist()
end)

api:notify("[AutoWhitelist] Loaded! Use /wl [name] to add users.", 5)
