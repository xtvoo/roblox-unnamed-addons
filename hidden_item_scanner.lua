-- Hidden Item Scanner for Da Hood
-- Scans common storage locations for specific item names

local searchTerms = {
    "Iron Man",
    "IronMan",
    "Suit",
    "Hamr",
    "Hammer",
    "Admin",
    "Hidden",
    "Dev"
}

-- Use GetService to safely get services, and only scan client-accessible ones
local servicesToScan = {
    "ReplicatedStorage",
    "Lighting",
    "Workspace",
    "StarterPack"
}

local function matchName(name)
    local lowerName = name:lower()
    for _, term in ipairs(searchTerms) do
        if lowerName:find(term:lower()) then
            return true
        end
    end
    return false
end

local function scan(serviceName)
    local service = game:GetService(serviceName)
    if not service then return end

    print("Scanning " .. serviceName .. "...")
    
    -- Recursive function to scan descendants safely
    -- We use GetDescendants() which is usually fine, but let's wrap it just in case
    local success, descendants = pcall(function()
        return service:GetDescendants()
    end)

    if not success then
        warn("Failed to get descendants for " .. serviceName)
        return
    end

    for _, obj in ipairs(descendants) do
        if matchName(obj.Name) then
            print("FOUND: " .. obj.Name .. " | Class: " .. obj.ClassName .. " | Path: " .. obj:GetFullName())
        end
    end
end

print("--- STARTING HIDDEN ITEM SCAN (V2) ---")
for _, serviceName in ipairs(servicesToScan) do
    pcall(function()
        scan(serviceName)
    end)
end
print("--- SCAN COMPLETE ---")
