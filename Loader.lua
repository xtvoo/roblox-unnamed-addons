local Repo = "https://raw.githubusercontent.com/xtvoo/roblox-unnamed-addons/main/"

local function UrlEncode(String)
    return (String:gsub("[^%w%-_%.~]", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end

local function LoadScript(Script)
    -- Encode spaces and special chars to match GitHub raw URL format
    local EncodedScript = UrlEncode(Script)
    return loadstring(game:HttpGet(Repo .. EncodedScript))()
end

getgenv().LoadScript = LoadScript

-- Example Usage:
-- LoadScript("auto kil with bag - Copy.txt") -> https://.../auto%20kil%20with%20bag%20-%20Copy.txt
-- LoadScript("auto_bag_v2.lua")

print("Loader Active! Use LoadScript('filename') to run scripts.")
