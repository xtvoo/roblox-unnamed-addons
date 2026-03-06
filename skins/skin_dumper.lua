-- Da Hood Skin Dumper - Unnamed Addon

-- Try multiple ways to get API
local api = ... or getfenv().api or _G.api or shared.api

if not api then
    -- Fallback: just run without API
    print("[SkinDumper] Running without API...")
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local output = {}
    
    local function log(text)
        table.insert(output, text)
    end
    
    log("-- DA HOOD SKIN DUMP --")
    log("local SkinData = {")
    
    local SkinModules = ReplicatedStorage:FindFirstChild("SkinModules")
    local skinCount = 0
    local meshCount = 0
    
    if SkinModules then
        local Meshes = SkinModules:FindFirstChild("Meshes")
        if Meshes then
            for _, skinFolder in ipairs(Meshes:GetChildren()) do
                if skinFolder:IsA("Folder") then
                    skinCount = skinCount + 1
                    log(string.format('    ["%s"] = {', skinFolder.Name))
                    
                    for _, item in ipairs(skinFolder:GetChildren()) do
                        if item:IsA("MeshPart") then
                            meshCount = meshCount + 1
                            local textureId = ""
                            pcall(function() textureId = item.TextureID end)
                            
                            if textureId and textureId ~= "" then
                                log(string.format('        ["%s"] = "%s",', item.Name, textureId))
                            end
                        end
                    end
                    
                    log('    },')
                end
            end
        end
    end
    
    log("}")
    log(string.format("-- Total: %d skins, %d meshes", skinCount, meshCount))
    
    local outputStr = table.concat(output, "\n")
    
    -- Try to save
    pcall(function()
        if writefile then
            writefile("DaHoodSkinDump.txt", outputStr)
            print("✅ Saved to DaHoodSkinDump.txt")
        end
    end)
    
    pcall(function()
        if setclipboard then
            setclipboard(outputStr)
            print("✅ Copied to clipboard!")
        end
    end)
    
    print("\n" .. outputStr)
    print("\n✅ Done! " .. skinCount .. " skins, " .. meshCount .. " meshes")
    
    return
end

-- If we have API, use it
api:set_lua_name("SkinDumper")
api:notify("Starting skin dump...", 2)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local output = {}

local function log(text)
    table.insert(output, text)
end

log("-- DA HOOD SKIN DUMP --")
log("local SkinData = {")

local SkinModules = ReplicatedStorage:FindFirstChild("SkinModules")
local skinCount = 0
local meshCount = 0

if SkinModules then
    local Meshes = SkinModules:FindFirstChild("Meshes")
    if Meshes then
        for _, skinFolder in ipairs(Meshes:GetChildren()) do
            if skinFolder:IsA("Folder") then
                skinCount = skinCount + 1
                log(string.format('    ["%s"] = {', skinFolder.Name))
                
                for _, item in ipairs(skinFolder:GetChildren()) do
                    if item:IsA("MeshPart") then
                        meshCount = meshCount + 1
                        local textureId = ""
                        pcall(function() textureId = item.TextureID end)
                        
                        if textureId and textureId ~= "" then
                            log(string.format('        ["%s"] = "%s",', item.Name, textureId))
                        end
                    end
                end
                
                log('    },')
            end
        end
    end
end

log("}")
log(string.format("-- Total: %d skins, %d meshes", skinCount, meshCount))

local outputStr = table.concat(output, "\n")

pcall(function()
    if writefile then
        writefile("DaHoodSkinDump.txt", outputStr)
        api:notify("Saved to DaHoodSkinDump.txt", 3)
    end
end)

pcall(function()
    if setclipboard then
        setclipboard(outputStr)
        api:notify("Copied to clipboard!", 3)
    end
end)

print("\n" .. outputStr)
api:notify("Done! " .. skinCount .. " skins, " .. meshCount .. " meshes", 3)

api:on_event("unload", function() end)
