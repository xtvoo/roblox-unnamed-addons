--[[
    UNNAMED UNIVERSAL DUMPER V2
    - Search for 'api' in all scopes
    - UI Integration (Button)
    - Recursive Dump of Settings Tables (RageBox, VoidBox, etc.)
]]

local OutputFile = "unnamed_full_dump.txt"
local Lines = {}

local function Log(str)
    table.insert(Lines, str)
end

local function SafeType(v)
    local s, r = pcall(typeof, v)
    return s and r or "unknown"
end

local function SafeToString(v)
    local s, r = pcall(tostring, v)
    return s and r or "<error>"
end

-- Recursive Table Dumper
local function DumpTable(tbl, name, depth, seen)
    seen = seen or {}
    if seen[tbl] then 
        Log(string.rep("  ", depth) .. "... (Cyclic)")
        return 
    end
    seen[tbl] = true
    
    if depth > 4 then 
        Log(string.rep("  ", depth) .. "... (Depth Limit)")
        return 
    end

    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)

    for _, k in ipairs(keys) do
        local v = tbl[k]
        local typeStr = SafeType(v)
        local valStr = SafeToString(v)
        
        if #valStr > 150 then valStr = string.sub(valStr, 1, 147) .. "..." end
        
        Log(string.rep("  ", depth) .. string.format("[%s] %s = %s", typeStr, tostring(k), valStr))
        
        -- Recurse into tables, but skip standard globals
        if typeStr == "table" and k ~= "_G" and k ~= "shared" and k ~= "package" and k ~= "coroutine" and k ~= "debug" and k ~= "os" and k ~= "string" and k ~= "math" and k ~= "table" then
            DumpTable(v, name, depth + 1, seen)
        end
    end
end

local function RunDump()
    Lines = {}
    Log("=== UNNAMED UNIVERSAL DUMP V2 ===")
    Log("Timestamp: " .. os.date("!%Y-%m-%dT%H:%M:%SZ"))
    Log("")

    -- 1. FIND API
    Log("--- CHEAT API SEARCH ---")
    local foundAPI = nil
    
    -- Check local scope (upvalues/env), _G, shared, getgenv
    if api then 
        Log("Found 'api' in Script Environment")
        foundAPI = api 
    elseif _G.api then 
        Log("Found 'api' in _G")
        foundAPI = _G.api
    elseif shared and shared.api then 
        Log("Found 'api' in shared")
        foundAPI = shared.api
    elseif getgenv().api then
        Log("Found 'api' in getgenv")
        foundAPI = getgenv().api
    else
        Log("CRITICAL: 'api' table NOT found in standard scopes.")
    end

    if foundAPI then
        DumpTable(foundAPI, "api", 0)
    end
    Log("")

    -- 2. SETTINGS BOXES (The "Juju-like" flags)
    Log("--- SETTINGS BOXES (Global Configs) ---")
    local env = getgenv()
    for k, v in pairs(env) do
        -- Dump anything ending in 'Box' (RageBox, VoidBox, etc) or specific known tables like 'Options', 'Toggles'
        if type(v) == "table" and (string.match(k, "Box$") or k == "Options" or k == "Toggles" or k == "Library") then
            Log(string.format(">>> DUMPING: %s <<<", k))
            DumpTable(v, k, 1)
            Log("")
        end
    end

    -- 3. GLOBAL ENVIRONMENT (Keys Only for non-boxes)
    Log("--- OTHER GLOBALS (getgenv) ---")
    for k, v in pairs(env) do
        if k ~= "_G" and k ~= "shared" and k ~= "api" and not string.match(k, "Box$") and k ~= "Options" and k ~= "Toggles" then
            Log(string.format("[%s] %s", SafeType(v), tostring(k)))
        end
    end
    Log("")

    -- 4. REMOTE SCANNER
    Log("--- REMOTE SCANNER (ReplicatedStorage & Workspace) ---")
    local function ScanRemotes(parent)
        local children = parent:GetChildren()
        for _, child in ipairs(children) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                Log(string.format("[%s] %s (Parent: %s)", child.ClassName, child.Name, parent:GetFullName()))
            elseif child:IsA("Folder") or child.Name == "Remotes" or child.Name == "Events" then
                ScanRemotes(child)
            end
        end
    end
    
    pcall(function() ScanRemotes(game:GetService("ReplicatedStorage")) end)
    pcall(function() ScanRemotes(game:GetService("Workspace")) end)
    Log("")

    -- OUTPUT
    local content = table.concat(Lines, "\n")
    
    if writefile then
        writefile(OutputFile, content)
    end
    
    if setclipboard then
        setclipboard(content)
    end
    
    if foundAPI and foundAPI.notify then
        foundAPI:notify("Dump Saved to " .. OutputFile, 5)
    end
end

-- UI INTEGRATION
-- Only try to add UI if 'api' is available immediately
if api then
    local success, err = pcall(function()
        local Tab = api:GetTab("Dumper") or api:AddTab("Dumper")
        local Group = Tab:AddLeftGroupbox("Universal Dumper")
        
        Group:AddButton("Dump Everything", function()
            RunDump()
        end)
        
        api:notify("Dumper Scripts Loaded. Check 'Dumper' Tab.", 5)
    end)
    
    if not success then
        warn("UI Creation Failed: " .. tostring(err))
        RunDump() -- Fallback to auto-run
    end
else
    -- If no 'api' global at start, just run logic (might be in auto-exec without UI support)
    RunDump()
end
