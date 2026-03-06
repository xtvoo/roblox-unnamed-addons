-- Configuration
local TargetUsername = "" -- REPLACE THIS with the name of the player you want to check. Leave empty for yourself.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Clean up previous runs
for _, v in pairs(workspace:GetChildren()) do
    if v.Name == "InventoryCheckSocket" then v:Destroy() end
end

print("\n\n--- Starting Inventory Check ---")

local TargetPlayer = nil

if TargetUsername and TargetUsername ~= "" then
    print("Searching for player matching: '" .. TargetUsername .. "'")
    local potential = {}
    for _, p in pairs(Players:GetPlayers()) do
        if string.find(string.lower(p.Name), string.lower(TargetUsername)) or 
           string.find(string.lower(p.DisplayName), string.lower(TargetUsername)) then
            table.insert(potential, p)
        end
    end
    
    if #potential == 1 then
        TargetPlayer = potential[1]
        print("Found target: " .. TargetPlayer.Name)
    elseif #potential > 1 then
        warn("Multiple players found matching '" .. TargetUsername .. "':")
        for _, p in pairs(potential) do warn("- " .. p.Name) end
        return warn("Please be more specific.")
    else
        warn("No player found matching '" .. TargetUsername .. "'. Available players:")
        for _, p in pairs(Players:GetPlayers()) do print("- " .. p.Name) end
        return warn("Aborting. Please check the username.")
    end
else
    print("No TargetUsername specified. Defaulting to LocalPlayer (" .. LocalPlayer.Name .. ").")
    TargetPlayer = LocalPlayer
end

-- Check DataFolder availability
print("Looking for DataFolder for " .. TargetPlayer.Name .. "...")

local DataFolder = TargetPlayer:FindFirstChild("DataFolder")
if not DataFolder then
    warn("DataFolder NOT found in " .. TargetPlayer.Name .. " (Player Object).")
    warn("Attempting to wait 5 seconds incase it's loading...")
    DataFolder = TargetPlayer:WaitForChild("DataFolder", 5)
end

if not DataFolder then
    warn("CRITICAL: Could not find DataFolder for " .. TargetPlayer.Name .. ".")
    warn("This likely means the game does NOT replicate other players' skin data to your client.")
    warn("You can only check your own inventory if the game doesn't expose this data.")
    return
end

local SkinsObject = DataFolder:WaitForChild("Skins", 5)
if not SkinsObject then
    return warn(" 'Skins' object missing in DataFolder for " .. TargetPlayer.Name)
end

-- URL provided by user for values
local DATA_URL = "https://raw.githubusercontent.com/xtvoo/dh-skin-values/refs/heads/main/values"

-- 1. Fetch Values from GitHub
local function fetchAndParseValues()
    print("Fetching skin values from GitHub...")
    local success, content = pcall(function()
        return game:HttpGet(DATA_URL)
    end)
    
    if not success then
        error("Failed to fetch skin values from GitHub: " .. tostring(content))
    end
    
    -- Structure: values[Category][SkinName] = Price
    local values = {}
    
    for line in string.gmatch(content, "[^\r\n]+") do
        -- Format: [Category] Name: Value
        local catStart, catEnd = string.find(line, "%[.-%]")
        local valSep = string.find(line, ": ")
        
        if catStart and catEnd and valSep then
            local category = string.sub(line, catStart, catEnd) 
            local name = string.sub(line, catEnd + 2, valSep - 1)
            local valStr = string.sub(line, valSep + 2)
            
            local cleanVal = string.gsub(valStr, ",", "")
            local numVal = 0
            
            if string.find(cleanVal, "M") then
                cleanVal = string.gsub(cleanVal, "M", "")
                numVal = (tonumber(cleanVal) or 0) * 1000000
            else
                numVal = tonumber(cleanVal) or 0
            end
            
            if not values[category] then
                values[category] = {}
            end
            
            values[category][name] = numVal
        end
    end
    
    return values
end

-- 2. fetch DataFolder.Skins.Value (JSON)
local function getInventoryData()
    print("Reading inventory data for " .. TargetPlayer.Name .. "...")
    if not SkinsObject:IsA("StringValue") then
        print("Warning: DataFolder.Skins is " .. SkinsObject.ClassName .. ", expected StringValue. Trying .Value anyway.")
    end
    
    local rawJson = SkinsObject.Value
    if rawJson == "" or rawJson == "[]" or rawJson == "{}" then
        warn("Inventory JSON is empty for " .. TargetPlayer.Name)
        return {}
    end
    
    local success, data = pcall(function() return HttpService:JSONDecode(rawJson) end)
    if not success then
        warn("Failed to decode inventory JSON: " .. tostring(data))
        return {}
    end
    
    return data
end

-- Parse Values matches
local SkinValues = fetchAndParseValues()
local InventoryData = getInventoryData()

local totalValue = 0
local detailedItems = {}

print("--- Calculating Inventory Value (" .. TargetPlayer.Name .. ") ---")

-- Mapping Inventory Categories to Text File Categories
local CategoryMap = {
    ["[Double-Barrel SG]"] = "[Double Barrel]",
    ["[TacticalShotgun]"] = "[Tactical SG]",
    ["[Revolver]"] = "[Revolver]",
    ["[RPG]"] = "[RPG]",
    ["[Flamethrower]"] = "[Flamethrower]",
    ["[Shotgun]"] = "[Shotgun]",
    ["[AK47]"] = "[AK47]",
    ["[AR]"] = "[AR]",
    ["[AUG]"] = "[AUG]",
    ["[SMG]"] = "[SMG]",
    ["[LMG]"] = "[LMG]",
    ["[P90]"] = "[P90]",
    ["[DrumGun]"] = "[DrumGun]", 
    ["[Glock]"] = "[Glock]",
    ["[Silencer]"] = "[Silencer]",
    ["[SilencerAR]"] = "[SilencerAR]",
    ["[Knife]"] = "[Knife]",
    ["[Wallet]"] = "[Wallet]",
}

for categoryName, items in pairs(InventoryData) do
    local lookupCategory = CategoryMap[categoryName] or categoryName
    local categoryTable = SkinValues[lookupCategory]
    
    -- Fallbacks
    if not categoryTable and categoryName == "[DrumGun]" then
        categoryTable = SkinValues["[DrumShotgun]"]
    end
    
    if not categoryTable then
        -- Loose match
        for fileCat, _ in pairs(SkinValues) do
            local cleanFile = fileCat:gsub("%W", ""):lower()
            local cleanInv = categoryName:gsub("%W", ""):lower()
            if cleanFile == cleanInv then
                categoryTable = SkinValues[fileCat]
                break
            end
        end
    end

    if categoryTable then
        for skinName, quantity in pairs(items) do
            if quantity > 0 then
                local unitValue = categoryTable[skinName] or 0
                local stackValue = unitValue * quantity
                
                if unitValue > 0 then
                    totalValue = totalValue + stackValue
                end
                
                table.insert(detailedItems, {
                    Name = skinName,
                    Category = categoryName,
                    Qty = quantity,
                    UnitVal = unitValue,
                    StackVal = stackValue
                })
            end
        end
    else
        -- Category Unknown
        for skinName, quantity in pairs(items) do
             if quantity > 0 then
                table.insert(detailedItems, {
                    Name = skinName,
                    Category = categoryName .. " (Unknown)",
                    Qty = quantity,
                    UnitVal = 0,
                    StackVal = 0
                })
             end
        end
    end
end

-- Sort by Stack Value (Descending)
print("Sorting inventory by value...")
table.sort(detailedItems, function(a, b)
    return a.StackVal > b.StackVal
end)

-- Formatting Helper
local function formatNum(n)
    return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local finalOutput = "--- Inventory Value Report: " .. TargetPlayer.Name .. " ---\n"
finalOutput = finalOutput .. "Total Account Value: $" .. formatNum(totalValue) .. "\n\n"
finalOutput = finalOutput .. "--- Detailed Breakdown (Sorted by Total Value) ---\n"
finalOutput = finalOutput .. string.format("%-3s | %-20s | %-30s | %-5s | %-12s | %-12s\n", "#", "Category", "Skin Name", "Qty", "Unit Value", "Total Value")
finalOutput = finalOutput .. string.rep("-", 100) .. "\n"

for i, item in ipairs(detailedItems) do
    local line = string.format("%-3d | %-20s | %-30s | %-5d | $% -11s | $% -11s", 
        i,
        item.Category, 
        item.Name, 
        item.Qty, 
        formatNum(item.UnitVal), 
        formatNum(item.StackVal)
    )
    finalOutput = finalOutput .. line .. "\n"
end

print("\n" .. finalOutput)

if writefile then
    local saneName = TargetPlayer.Name:gsub("%W", "_")
    local outputPath = "da hood/Skins_Value_" .. saneName .. ".txt"
    pcall(writefile, outputPath, finalOutput)
    print("Saved detailed report to: " .. outputPath)
    
    if rconsoleprint then
        rconsoleprint("\nDetailed report saved to " .. outputPath)
    end
else
    print("Executor does not support writefile.")
end
