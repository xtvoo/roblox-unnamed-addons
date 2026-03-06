-- Whitelist Activity Logger
-- Monitors specific UI IDs for value changes and logs them to a file.
-- Use this to reverse-engineer the correct ID and Value format.

api:set_lua_name("Whitelist_Logger")

local LOG_FILE = "whitelist_logs.txt"
writefile(LOG_FILE, "--- WHITELIST LOGGER STARTED ---\n")

local function log_to_file(msg)
    print(msg)
    appendfile(LOG_FILE, msg .. "\n")
end

-- List of IDs to monitor
local candidate_ids = {
    "ragebot_whitelist",
    "whitelist",
    "Whitelist",
    "Target Whitelist",
    "Priority Whitelist",
    "combat_whitelist",
    "ragebot_target_whitelist",
    "protector_whitelist" -- Our own, just to see if it works
}

-- Store last known values to detect changes
local cache = {}

log_to_file("[Logger] Monitoring " .. #candidate_ids .. " potential IDs for changes...")

-- Main Loop
task.spawn(function()
    while task.wait(0.5) do
        for _, id in ipairs(candidate_ids) do
            local obj = api:get_ui_object(id)
            
            if obj then
                -- 1. Grab current value
                local current_val = obj.Value
                local encoded_val = "nil"
                pcall(function() encoded_val = game:GetService("HttpService"):JSONEncode(current_val) end)
                
                -- 2. Check against cache
                if cache[id] ~= encoded_val then
                    -- Change detected!
                    if cache[id] == nil then
                        log_to_file(string.format("[FOUND] ID '%s' exists! Initial Value: %s", id, encoded_val))
                    else
                        log_to_file(string.format("[CHANGE] ID '%s' updated!", id))
                        log_to_file("   > OLD: " .. tostring(cache[id]))
                        log_to_file("   > NEW: " .. tostring(encoded_val))
                        
                        -- Inspect internals if table
                        if type(current_val) == "table" then
                            log_to_file("   > Table Structure Inspection:")
                            for k, v in pairs(current_val) do
                                log_to_file(string.format("      [%s] (%s) = %s", tostring(k), type(k), tostring(v)))
                            end
                        end
                    end
                    
                    -- Update cache
                    cache[id] = encoded_val
                end
            end
        end
    end
end)

api:notify("Logger Running! Add a player to the whitelist now.", 5)
