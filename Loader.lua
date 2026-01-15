local Repo = "https://raw.githubusercontent.com/xtvoo/roblox-unnamed-addons/main/"

local function LoadScript(Script)
    return loadstring(game:HttpGet(Repo .. Script))()
end

getgenv().LoadScript = LoadScript

-- Example Usage:
-- LoadScript("auto kil with bag - Copy.txt")
-- LoadScript("auto_bag_v2.lua")

print("Loader Active! Use LoadScript('filename') to run scripts.")
