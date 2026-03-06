-- Debug Whitelist UI Object
-- Purpose: Find the REAL name and format of the whitelist dropdown.

local candidates = {
    "ragebot_whitelist",
    "Whitelist",
    "whitelist",
    "Target Whitelist",
    "Friends Whitelist", 
    "combat_whitelist"
}

print("--- START WHITELIST DEBUG ---")

for _, id in ipairs(candidates) do
    local obj = api:get_ui_object(id)
    if obj then
        print("FOUND OBJECT: " .. id)
        
        -- Check Value Type
        local val = obj.Value
        print("  > Value Type: " .. type(val))
        
        -- Print content sample
        if type(val) == "table" then
            local count = 0
            for k, v in pairs(val) do 
                print("  > Sample Val ["..tostring(k).."]: " .. tostring(v))
                count = count + 1
                if count > 5 then break end
            end
        else
            print("  > Value: " .. tostring(val))
        end
        
        -- Check Options
        local opts = obj.Options or obj.Values
        if opts then
            print("  > Options found ("..#opts..")")
            if #opts > 0 then
                print("  > Sample Option: " .. tostring(opts[1]))
            end
        else
            print("  > No Options/Values table found.")
        end
        
        print("---------------------------")
    else
        print("NOT FOUND: " .. id)
    end
end

print("--- END WHITELIST DEBUG ---")
api:notify("Check F9 Console for Whitelist Info", 5)
