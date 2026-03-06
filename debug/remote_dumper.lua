-- Da Hood Remote/Event Dumper
-- Finds all RemoteEvents, RemoteFunctions, and BindableEvents in the game

local dumped = {}
local categories = {
    ReplicatedStorage = {},
    Workspace = {},
    Players = {},
    Other = {}
}

print("=" :rep(60))
print("🔍 DUMPING ALL GAME REMOTES...")
print("=" :rep(60))

-- Function to categorize and dump
local function dumpRemote(remote)
    local fullPath = remote:GetFullName()
    
    -- Avoid duplicates
    if dumped[fullPath] then return end
    dumped[fullPath] = true
    
    local info = {
        Name = remote.Name,
        Type = remote.ClassName,
        Path = fullPath,
        Parent = remote.Parent and remote.Parent.Name or "nil"
    }
    
    -- Categorize by location
    if fullPath:find("ReplicatedStorage") then
        table.insert(categories.ReplicatedStorage, info)
    elseif fullPath:find("Workspace") then
        table.insert(categories.Workspace, info)
    elseif fullPath:find("Players") then
        table.insert(categories.Players, info)
    else
        table.insert(categories.Other, info)
    end
end

-- Scan the entire game
for _, obj in pairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
        dumpRemote(obj)
    end
end

-- Print categorized results
print("\n📁 REPLICATED STORAGE (" .. #categories.ReplicatedStorage .. " remotes)")
print("-" :rep(60))
for _, info in pairs(categories.ReplicatedStorage) do
    print(string.format("  [%s] %s", info.Type, info.Path))
end

print("\n🌍 WORKSPACE (" .. #categories.Workspace .. " remotes)")
print("-" :rep(60))
for _, info in pairs(categories.Workspace) do
    print(string.format("  [%s] %s", info.Type, info.Path))
end

print("\n👤 PLAYERS (" .. #categories.Players .. " remotes)")
print("-" :rep(60))
for _, info in pairs(categories.Players) do
    print(string.format("  [%s] %s", info.Type, info.Path))
end

print("\n📦 OTHER LOCATIONS (" .. #categories.Other .. " remotes)")
print("-" :rep(60))
for _, info in pairs(categories.Other) do
    print(string.format("  [%s] %s", info.Type, info.Path))
end

-- Search for arrest-related remotes
print("\n\n🚔 ARREST-RELATED REMOTES:")
print("-" :rep(60))
local foundArrest = false
for path, _ in pairs(dumped) do
    local lower = path:lower()
    if lower:find("arrest") or lower:find("cuff") or lower:find("jail") or lower:find("police") then
        print("  ✅ " .. path)
        foundArrest = true
    end
end
if not foundArrest then
    print("  ❌ No arrest-related remotes found by name")
    print("  💡 Try checking MainEvent or common remotes manually")
end

-- Summary
local total = 0
for _, cat in pairs(categories) do
    total = total + #cat
end

print("\n" .. "=" :rep(60))
print(string.format("✅ DUMP COMPLETE: Found %d total remotes", total))
print("=" :rep(60))
print("\n💡 TIP: Look for 'MainEvent' in ReplicatedStorage")
print("💡 TIP: Most Da Hood remotes use MainEvent:FireServer(action, args)")
print("=" :rep(60))

-- Save to file (if supported)
pcall(function()
    local output = "DA HOOD REMOTE DUMP\n" .. "=" :rep(60) .. "\n\n"
    
    for category, remotes in pairs(categories) do
        output = output .. category .. " (" .. #remotes .. " remotes)\n"
        output = output .. "-" :rep(60) .. "\n"
        for _, info in pairs(remotes) do
            output = output .. string.format("[%s] %s\n", info.Type, info.Path)
        end
        output = output .. "\n"
    end
    
    writefile("dahood_remote_dump.txt", output)
    print("\n💾 Saved to: dahood_remote_dump.txt")
end)
