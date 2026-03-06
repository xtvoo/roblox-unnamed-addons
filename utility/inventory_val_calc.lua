local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local DataFolder = LocalPlayer:WaitForChild("DataFolder")
local SkinsObject = DataFolder:WaitForChild("Skins")

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
    
    local values = {}
    
    for line in string.gmatch(content, "[^\r\n]+") do
        local catEnd = string.find(line, "]")
        local valSep = string.find(line, ": ")
        
        if catEnd and valSep then
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
            
            if values[name] then
                if numVal > values[name] then
                    values[name] = numVal
                end
            else
                values[name] = numVal
            end
        end
    end
    
    return values
end

-- 2. fetch DataFolder.Skins.Value (JSON)
local function getInventoryData()
    print("Reading inventory data...")
    if not SkinsObject:IsA("StringValue") then
        print("Warning: DataFolder.Skins is " .. SkinsObject.ClassName .. ", expected StringValue. Trying .Value anyway.")
    end
    
    local rawJson = SkinsObject.Value
    if rawJson == "" or rawJson == "[]" or rawJson == "{}" then
        warn("Inventory JSON is empty.")
        return {}
    end
    
    local success, data = pcall(function() return HttpService:JSONDecode(rawJson) end)
    if not success then
        warn("Failed to decode inventory JSON: " .. tostring(data))
        return {}
    end
    
    return data
end

-- Run
local SkinValues = fetchAndParseValues()
local InventoryData = getInventoryData()

local totalValue = 0
local inventoryList = {}

print("--- Calculating Inventory Value ---")

-- InventoryData structure provided by user:
-- { "[Rifle]": { "SkinName": Quantity, ... }, ... }

for categoryName, items in pairs(InventoryData) do
    for skinName, quantity in pairs(items) do
        if quantity > 0 then
            local unitValue = SkinValues[skinName]
            if unitValue then
                local stackValue = unitValue * quantity
                totalValue = totalValue + stackValue
            end
        end
    end
end

local finalOutput = "--- Inventory Value Report ---\n"
finalOutput = finalOutput .. "Total Account Value: " .. tostring(totalValue) .. "\n"

print("\n" .. finalOutput)

if writefile then
    local outputPath = "da hood/Skins_Value_Report_Final.txt"
    pcall(writefile, outputPath, finalOutput)
    print("Saved report to: " .. outputPath)
else
    print("Executor does not support writefile.")
end
