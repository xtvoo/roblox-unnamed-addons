--[[
    Debug Utilities v2.0 - API Explorer
    Explore tables, find UI flags, dump API methods
    See what's possible behind the scenes
]]

api:set_lua_name("Debug_Explorer")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==================== UI SETUP ====================
local tab = api:GetTab("misc") or api:AddTab("misc")
local debugBox = tab:AddLeftGroupbox("🔍 API Explorer")

-- MASTER DUMP BUTTON
debugBox:AddButton("💾 DUMP EVERYTHING TO FILE", function()
    dumpEverythingToFile()
end)

debugBox:AddDivider()

-- Dump buttons
debugBox:AddButton("Dump API Methods", function()
    dumpAPIMethods()
end)

debugBox:AddButton("Dump UI Flags (Options)", function()
    dumpUIFlags()
end)

debugBox:AddButton("Dump UI Flags (Toggles)", function()
    dumpToggles()
end)

debugBox:AddButton("Dump All Tabs", function()
    dumpTabs()
end)

debugBox:AddButton("Dump getgenv()", function()
    dumpGetgenv()
end)

local exploreBox = tab:AddRightGroupbox("📦 Table Explorer")

local tableInput = exploreBox:AddInput("dbg_table_path", {
    Text = "Table Path",
    Default = "api",
    Placeholder = "e.g. api, Options, Toggles, getgenv()"
})

exploreBox:AddButton("Explore Table", function()
    local path = api:get_ui_object("dbg_table_path")
    if path and path.Value then
        exploreTable(path.Value)
    end
end)

exploreBox:AddButton("Copy Last Dump", function()
    if _G.lastDump then
        setclipboard(_G.lastDump)
        api:notify("Copied to clipboard!", 2)
    end
end)

local uiBox = tab:AddLeftGroupbox("🎛️ UI Object Inspector")

local flagInput = uiBox:AddInput("dbg_flag_name", {
    Text = "Flag Name",
    Default = "ragebot_keybind",
    Placeholder = "e.g. ragebot_keybind, character_prot_void"
})

uiBox:AddButton("Inspect UI Object", function()
    local flag = api:get_ui_object("dbg_flag_name")
    if flag and flag.Value then
        inspectUIObject(flag.Value)
    end
end)

uiBox:AddButton("Set UI Value", function()
    -- Will prompt for value
    local flag = api:get_ui_object("dbg_flag_name")
    if flag and flag.Value then
        local obj = api:get_ui_object(flag.Value)
        if obj then
            api:notify("Current value: " .. tostring(obj.Value), 3)
        end
    end
end)

local modBox = tab:AddRightGroupbox("⚙️ Modify UI")

local setFlagInput = modBox:AddInput("dbg_set_flag", {
    Text = "Flag to Modify",
    Default = "",
    Placeholder = "Flag name"
})

local setValueInput = modBox:AddInput("dbg_set_value", {
    Text = "New Value",
    Default = "",
    Placeholder = "Value (true/false/number/string)"
})

modBox:AddButton("Set Value", function()
    local flagObj = api:get_ui_object("dbg_set_flag")
    local valueObj = api:get_ui_object("dbg_set_value")
    
    if flagObj and valueObj and flagObj.Value ~= "" then
        local uiObj = api:get_ui_object(flagObj.Value)
        if uiObj then
            local val = valueObj.Value
            -- Try to parse value
            if val == "true" then val = true
            elseif val == "false" then val = false
            elseif tonumber(val) then val = tonumber(val)
            end
            
            uiObj:SetValue(val)
            api:notify("Set " .. flagObj.Value .. " = " .. tostring(val), 2)
        else
            api:notify("Flag not found: " .. flagObj.Value, 3)
        end
    end
end)

modBox:AddButton("Override Keybind ON", function()
    local flagObj = api:get_ui_object("dbg_set_flag")
    if flagObj and flagObj.Value ~= "" then
        local uiObj = api:get_ui_object(flagObj.Value)
        if uiObj and uiObj.OverrideState then
            uiObj:OverrideState(true)
            api:notify("Overriding " .. flagObj.Value .. " ON", 2)
        end
    end
end)

modBox:AddButton("Override Keybind OFF", function()
    local flagObj = api:get_ui_object("dbg_set_flag")
    if flagObj and flagObj.Value ~= "" then
        local uiObj = api:get_ui_object(flagObj.Value)
        if uiObj and uiObj.OverrideState then
            uiObj:OverrideState(false)
            api:notify("Overriding " .. flagObj.Value .. " OFF", 2)
        end
    end
end)

-- ==================== MASTER DUMP TO FILE ====================

function dumpEverythingToFile()
    api:notify("Dumping everything... please wait", 3)
    
    local output = ""
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Header
    output = output .. string.rep("=", 80) .. "\n"
    output = output .. "UNNAMED API FULL DUMP\n"
    output = output .. "Generated: " .. timestamp .. "\n"
    output = output .. string.rep("=", 80) .. "\n\n"
    
    -- ===================== API METHODS =====================
    output = output .. string.rep("=", 80) .. "\n"
    output = output .. "SECTION 1: API METHODS\n"
    output = output .. string.rep("=", 80) .. "\n\n"
    
    local apiMethods = {}
    local apiProperties = {}
    
    for key, value in pairs(api) do
        if typeof(value) == "function" then
            table.insert(apiMethods, key)
        else
            table.insert(apiProperties, {key = key, type = typeof(value), value = tostring(value):sub(1, 100)})
        end
    end
    
    table.sort(apiMethods)
    
    output = output .. "-- Functions (" .. #apiMethods .. ") --\n"
    for _, method in ipairs(apiMethods) do
        output = output .. "api:" .. method .. "()\n"
    end
    
    output = output .. "\n-- Properties (" .. #apiProperties .. ") --\n"
    for _, prop in ipairs(apiProperties) do
        output = output .. "api." .. prop.key .. " = " .. prop.value .. " [" .. prop.type .. "]\n"
    end
    
    -- ===================== OPTIONS TABLE =====================
    output = output .. "\n" .. string.rep("=", 80) .. "\n"
    output = output .. "SECTION 2: OPTIONS TABLE (All UI Flags)\n"
    output = output .. string.rep("=", 80) .. "\n\n"
    
    if Options then
        local optionsList = {}
        for key, value in pairs(Options) do
            local val = value.Value
            local valStr = tostring(val)
            local valType = typeof(val)
            
            if valType == "table" then
                valStr = "{"
                local count = 0
                for k, v in pairs(val) do
                    if count > 0 then valStr = valStr .. ", " end
                    valStr = valStr .. tostring(k) .. "=" .. tostring(v)
                    count = count + 1
                    if count > 5 then valStr = valStr .. ", ..." break end
                end
                valStr = valStr .. "}"
            end
            
            table.insert(optionsList, {
                key = key,
                value = valStr,
                type = valType
            })
        end
        
        table.sort(optionsList, function(a, b) return a.key < b.key end)
        
        output = output .. "Total Options: " .. #optionsList .. "\n\n"
        
        for _, opt in ipairs(optionsList) do
            output = output .. opt.key .. " = " .. opt.value .. " [" .. opt.type .. "]\n"
        end
    else
        output = output .. "Options table not found!\n"
    end
    
    -- ===================== TOGGLES TABLE =====================
    output = output .. "\n" .. string.rep("=", 80) .. "\n"
    output = output .. "SECTION 3: TOGGLES TABLE\n"
    output = output .. string.rep("=", 80) .. "\n\n"
    
    if Toggles then
        local togglesList = {}
        for key, value in pairs(Toggles) do
            table.insert(togglesList, {
                key = key,
                value = value.Value
            })
        end
        
        table.sort(togglesList, function(a, b) return a.key < b.key end)
        
        output = output .. "Total Toggles: " .. #togglesList .. "\n\n"
        
        for _, tog in ipairs(togglesList) do
            output = output .. tog.key .. " = " .. tostring(tog.value) .. "\n"
        end
    else
        output = output .. "Toggles table not found!\n"
    end
    
    -- ===================== UI OBJECT DETAILS =====================
    output = output .. "\n" .. string.rep("=", 80) .. "\n"
    output = output .. "SECTION 4: DETAILED UI OBJECT INSPECTION\n"
    output = output .. string.rep("=", 80) .. "\n\n"
    
    if Options then
        for key, obj in pairs(Options) do
            output = output .. "--- " .. key .. " ---\n"
            
            -- Get all properties of this UI object
            local props = {}
            local methods = {}
            
            for k, v in pairs(obj) do
                if typeof(v) == "function" then
                    table.insert(methods, k)
                else
                    local valStr = tostring(v)
                    if #valStr > 80 then valStr = valStr:sub(1, 80) .. "..." end
                    table.insert(props, "  ." .. k .. " = " .. valStr .. " [" .. typeof(v) .. "]")
                end
            end
            
            table.sort(props)
            table.sort(methods)
            
            for _, p in ipairs(props) do
                output = output .. p .. "\n"
            end
            
            if #methods > 0 then
                output = output .. "  Methods: " .. table.concat(methods, ", ") .. "\n"
            end
            
            output = output .. "\n"
        end
    end
    
    -- ===================== GETGENV =====================
    output = output .. "\n" .. string.rep("=", 80) .. "\n"
    output = output .. "SECTION 5: GETGENV() GLOBALS\n"
    output = output .. string.rep("=", 80) .. "\n\n"
    
    local genvList = {}
    for key, value in pairs(getgenv()) do
        local valType = typeof(value)
        local valStr = ""
        
        if valType == "function" then
            valStr = "function"
        elseif valType == "table" then
            local count = 0
            for _ in pairs(value) do count = count + 1 end
            valStr = "table (" .. count .. " items)"
        else
            valStr = tostring(value):sub(1, 60)
        end
        
        table.insert(genvList, tostring(key) .. " = " .. valStr .. " [" .. valType .. "]")
    end
    
    table.sort(genvList)
    
    output = output .. "Total globals: " .. #genvList .. "\n\n"
    for _, g in ipairs(genvList) do
        output = output .. g .. "\n"
    end
    
    -- ===================== TABS =====================
    output = output .. "\n" .. string.rep("=", 80) .. "\n"
    output = output .. "SECTION 6: AVAILABLE TABS\n"
    output = output .. string.rep("=", 80) .. "\n\n"
    
    local tabNames = {"combat", "ragebot", "aimbot", "silent", "character", "misc", "settings", "visuals", "esp", "lua", "player", "world", "exploit", "teleport"}
    for _, tabName in ipairs(tabNames) do
        local t = api:GetTab(tabName)
        if t then
            output = output .. "[FOUND] " .. tabName .. "\n"
        end
    end
    
    -- ===================== FOOTER =====================
    output = output .. "\n" .. string.rep("=", 80) .. "\n"
    output = output .. "END OF DUMP\n"
    output = output .. "Total characters: " .. #output .. "\n"
    output = output .. string.rep("=", 80) .. "\n"
    
    -- Write to file
    local filename = "unnamed_api_dump_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    local filepath = filename
    
    local success, err = pcall(function()
        writefile(filepath, output)
    end)
    
    if success then
        api:notify("Saved to: " .. filepath, 5)
        print("\n" .. string.rep("=", 50))
        print("DUMP SAVED TO: " .. filepath)
        print(string.rep("=", 50) .. "\n")
    else
        api:notify("Failed to save file: " .. tostring(err), 5)
        -- Copy to clipboard instead
        setclipboard(output)
        api:notify("Copied to clipboard instead!", 3)
    end
    
    _G.lastDump = output
    
    return output
end

getgenv().dumpEverythingToFile = dumpEverythingToFile

-- ==================== DUMP FUNCTIONS ====================

function dumpAPIMethods()
    local output = "═══ API METHODS ═══\n\n"
    local count = 0
    
    for key, value in pairs(api) do
        local valueType = typeof(value)
        if valueType == "function" then
            output = output .. "🔹 api:" .. key .. "()\n"
        else
            output = output .. "📌 api." .. key .. " = " .. valueType .. "\n"
        end
        count = count + 1
    end
    
    output = output .. "\n═══ Total: " .. count .. " items ═══"
    
    _G.lastDump = output
    print(output)
    api:notify("Dumped " .. count .. " API methods to console", 3)
end

function dumpUIFlags()
    local output = "═══ UI FLAGS (Options) ═══\n\n"
    local count = 0
    
    if Options then
        for key, value in pairs(Options) do
            local val = value.Value
            local valStr = tostring(val)
            if typeof(val) == "table" then
                valStr = "{" .. #val .. " items}"
            end
            output = output .. "📌 " .. key .. " = " .. valStr .. " (" .. typeof(val) .. ")\n"
            count = count + 1
        end
    else
        output = output .. "Options table not found!\n"
    end
    
    output = output .. "\n═══ Total: " .. count .. " flags ═══"
    
    _G.lastDump = output
    print(output)
    api:notify("Dumped " .. count .. " Options flags to console", 3)
end

function dumpToggles()
    local output = "═══ UI FLAGS (Toggles) ═══\n\n"
    local count = 0
    
    if Toggles then
        for key, value in pairs(Toggles) do
            local val = value.Value
            output = output .. "🔘 " .. key .. " = " .. tostring(val) .. "\n"
            count = count + 1
        end
    else
        output = output .. "Toggles table not found!\n"
    end
    
    output = output .. "\n═══ Total: " .. count .. " toggles ═══"
    
    _G.lastDump = output
    print(output)
    api:notify("Dumped " .. count .. " Toggles to console", 3)
end

function dumpTabs()
    local output = "═══ UI TABS ═══\n\n"
    
    -- Try to find tabs through api
    if api.GetTab then
        local commonTabs = {"combat", "ragebot", "aimbot", "silent", "character", "misc", "settings", "visuals", "esp", "lua"}
        for _, tabName in ipairs(commonTabs) do
            local t = api:GetTab(tabName)
            if t then
                output = output .. "✓ Tab: " .. tabName .. "\n"
            end
        end
    end
    
    _G.lastDump = output
    print(output)
    api:notify("Dumped tabs to console", 3)
end

function dumpGetgenv()
    local output = "═══ getgenv() ═══\n\n"
    local count = 0
    
    for key, value in pairs(getgenv()) do
        local valueType = typeof(value)
        if valueType == "table" then
            local tableCount = 0
            for _ in pairs(value) do tableCount = tableCount + 1 end
            output = output .. "📦 " .. tostring(key) .. " = table (" .. tableCount .. " items)\n"
        elseif valueType == "function" then
            output = output .. "🔹 " .. tostring(key) .. " = function\n"
        else
            output = output .. "📌 " .. tostring(key) .. " = " .. tostring(value):sub(1, 50) .. "\n"
        end
        count = count + 1
        if count > 100 then
            output = output .. "... (truncated, too many items)\n"
            break
        end
    end
    
    output = output .. "\n═══ Total: " .. count .. "+ items ═══"
    
    _G.lastDump = output
    print(output)
    api:notify("Dumped getgenv() to console", 3)
end

function exploreTable(path)
    local output = "═══ EXPLORING: " .. path .. " ═══\n\n"
    local count = 0
    
    -- Try to get the table
    local tbl
    local success, err = pcall(function()
        if path == "api" then
            tbl = api
        elseif path == "Options" then
            tbl = Options
        elseif path == "Toggles" then
            tbl = Toggles
        elseif path == "getgenv()" then
            tbl = getgenv()
        elseif path:find("%.") then
            -- Handle nested paths like "api.something"
            local parts = path:split(".")
            tbl = _G[parts[1]] or getgenv()[parts[1]]
            for i = 2, #parts do
                if tbl then
                    tbl = tbl[parts[i]]
                end
            end
        else
            tbl = _G[path] or getgenv()[path]
        end
    end)
    
    if not tbl then
        output = output .. "❌ Could not find table: " .. path .. "\n"
        if err then output = output .. "Error: " .. tostring(err) .. "\n" end
    elseif typeof(tbl) ~= "table" then
        output = output .. "Value: " .. tostring(tbl) .. " (" .. typeof(tbl) .. ")\n"
    else
        for key, value in pairs(tbl) do
            local valueType = typeof(value)
            local valStr = tostring(value)
            
            if valueType == "function" then
                output = output .. "🔹 " .. tostring(key) .. "() -- function\n"
            elseif valueType == "table" then
                local subCount = 0
                for _ in pairs(value) do subCount = subCount + 1 end
                output = output .. "📦 " .. tostring(key) .. " -- table (" .. subCount .. " items)\n"
            else
                if #valStr > 60 then valStr = valStr:sub(1, 60) .. "..." end
                output = output .. "📌 " .. tostring(key) .. " = " .. valStr .. " (" .. valueType .. ")\n"
            end
            count = count + 1
            
            if count > 100 then
                output = output .. "\n... (truncated)\n"
                break
            end
        end
    end
    
    output = output .. "\n═══ Found: " .. count .. " items ═══"
    
    _G.lastDump = output
    print(output)
    api:notify("Explored " .. path .. " - " .. count .. " items", 3)
end

function inspectUIObject(flagName)
    local output = "═══ UI OBJECT: " .. flagName .. " ═══\n\n"
    
    local obj = api:get_ui_object(flagName)
    
    if not obj then
        output = output .. "❌ Not found!\n"
        output = output .. "\nTry searching in Options/Toggles tables.\n"
    else
        output = output .. "✓ Found!\n\n"
        
        -- Dump all properties
        for key, value in pairs(obj) do
            local valStr = tostring(value)
            if typeof(value) == "function" then
                output = output .. "🔹 :" .. key .. "() -- method\n"
            elseif typeof(value) == "table" then
                output = output .. "📦 ." .. key .. " -- table\n"
            else
                if #valStr > 50 then valStr = valStr:sub(1, 50) .. "..." end
                output = output .. "📌 ." .. key .. " = " .. valStr .. "\n"
            end
        end
        
        output = output .. "\n── Common Methods ──\n"
        output = output .. "obj:SetValue(value) -- Set the value\n"
        output = output .. "obj.Value -- Get current value\n"
        if obj.OverrideState then
            output = output .. "obj:OverrideState(bool) -- Force keybind\n"
        end
        if obj.SetValues then
            output = output .. "obj:SetValues(table) -- Update dropdown options\n"
        end
    end
    
    _G.lastDump = output
    print(output)
    api:notify("Inspected " .. flagName, 3)
end

-- ==================== QUICK ACCESS ====================

-- Add some quick dumps to console on load
print("\n" .. string.rep("═", 50))
print("DEBUG EXPLORER LOADED")
print("Use the misc tab to explore API and UI")
print(string.rep("═", 50) .. "\n")

-- Quick reference
print("Quick commands (run in console):")
print("  dumpAPIMethods() - See all API methods")
print("  dumpUIFlags() - See all Options")
print("  dumpToggles() - See all Toggles")
print("  exploreTable('api') - Explore any table")
print("  inspectUIObject('flag_name') - Inspect UI object")
print("")

-- Make functions global for console access
getgenv().dumpAPIMethods = dumpAPIMethods
getgenv().dumpUIFlags = dumpUIFlags
getgenv().dumpToggles = dumpToggles
getgenv().dumpTabs = dumpTabs
getgenv().dumpGetgenv = dumpGetgenv
getgenv().exploreTable = exploreTable
getgenv().inspectUIObject = inspectUIObject

-- ==================== CLEANUP ====================

api:on_event("unload", function()
    api:notify("Debug Explorer Unloaded", 2)
end)

api:notify("� Debug Explorer v2.0 Loaded!", 3)
