-- ULTIMATE ASSET DUMPER V3
-- Fixes "table expected got string" crash
-- Dumps ReplicatedStorage.SkinModules (Meshes, Textures)
-- Dumps ReplicatedStorage.SkinAssets (Sounds, etc.)

local api = getfenv().api or _G.api or shared.api
local Services = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    HttpService = game:GetService("HttpService"),
}

local function get_ids(obj)
    local ids = {}
    
    -- MESH / TEXTURE assets
    if obj:IsA("MeshPart") then
        if obj.TextureID ~= "" then ids.Texture = obj.TextureID end
        if obj.MeshId ~= "" then ids.Mesh = obj.MeshId end
    elseif obj:IsA("Part") or obj:IsA("UnionOperation") then
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("SpecialMesh") then
                if child.TextureId ~= "" then ids.Texture = child.TextureId end
                if child.MeshId ~= "" then ids.Mesh = child.MeshId end
            elseif child:IsA("Texture") or child:IsA("Decal") then
                if child.Texture ~= "" then ids.Texture = child.Texture end
            end
        end
    -- SOUND assets (Values or Sound objects)
    elseif obj:IsA("Sound") then
        if obj.SoundId ~= "" then ids.Sound = obj.SoundId end
    elseif obj:IsA("StringValue") or obj:IsA("IntValue") then
        local str = tostring(obj.Value)
        if str:match("rbxassetid") or str:match("%d+") then
             ids.Value = str
        end
    end
    
    return next(ids) and ids or nil
end

local function scan_folder(folder, depth, collection)
    for _, child in ipairs(folder:GetChildren()) do
        local ids = get_ids(child)
        if ids then
            -- Safely assign ids
            if collection[child.Name] and type(collection[child.Name]) == "table" then
                 -- If there's already a table, merge into it
                 for k,v in pairs(ids) do collection[child.Name][k] = v end
            else
                 collection[child.Name] = ids
            end
        end
        
        -- Recursively check containers
        if child:IsA("Folder") or child:IsA("Model") then
            local sub_collection = {}
            scan_folder(child, depth + 1, sub_collection)
            
            if next(sub_collection) then
                if collection[child.Name] and type(collection[child.Name]) == "table" then
                     for k,v in pairs(sub_collection) do collection[child.Name][k] = v end
                else
                     collection[child.Name] = sub_collection
                end
            end
        end
    end
end

local function dump_all()
    local RootData = {
        SkinModules = {},
        SkinAssets = {}
    }
    
    local sm = Services.ReplicatedStorage:FindFirstChild("SkinModules")
    if sm then scan_folder(sm, 1, RootData.SkinModules) end
    
    local sa = Services.ReplicatedStorage:FindFirstChild("SkinAssets")
    if sa then scan_folder(sa, 1, RootData.SkinAssets) end

    -- GENERATE OUTPUT
    local lines = {}
    table.insert(lines, "=== DA HOOD ULTIMATE SKIN DUMP V3 (FIXED) ===")
    table.insert(lines, "Generated: " .. os.date("%c"))
    table.insert(lines, "")
    
    local function print_tree(node, prefix)
        if type(node) ~= "table" then
             table.insert(lines, prefix .. "! NON-TABLE VALUE: " .. tostring(node))
             return
        end

        local keys = {}
        for k in pairs(node) do table.insert(keys, k) end
        table.sort(keys)
        
        for _, k in ipairs(keys) do
            local v = node[k]
            if type(v) == "table" and (v.Texture or v.Mesh or v.Sound or v.Value) then
                local info = string.format("%s- %s", prefix, k)
                if v.Texture then info = info .. " | Tex: " .. v.Texture end
                if v.Mesh then info = info .. " | Mesh: " .. v.Mesh end
                if v.Sound then info = info .. " | Sound: " .. v.Sound end
                if v.Value then info = info .. " | Val: " .. v.Value end
                table.insert(lines, info)
            else
                table.insert(lines, string.format("%s[%s]", prefix, k))
                print_tree(v, prefix .. "  ")
            end
        end
    end
    
    print_tree(RootData, "")
    
    -- LUA TABLE FORMAT
    table.insert(lines, "\n" .. string.rep("=", 30))
    table.insert(lines, "LUA DATA TABLE")
    table.insert(lines, string.rep("=", 30) .. "\n")
    
    local lua_str = "local Everything = {\n"
    
    for topKey, topData in pairs(RootData) do
        lua_str = lua_str .. string.format('    ["%s"] = {\n', topKey)
        
        if type(topData) == "table" then
            local cats = {}
            for k in pairs(topData) do table.insert(cats, k) end
            table.sort(cats)
            
            for _, cat in ipairs(cats) do
                local catData = topData[cat]
                
                -- CRASH FIX: Check if catData is actually a table
                if type(catData) == "table" then
                    lua_str = lua_str .. string.format('        ["%s"] = {\n', cat)
                    
                    local skins = {}
                    for k in pairs(catData) do table.insert(skins, k) end
                    table.sort(skins)
                    
                    for _, skinName in ipairs(skins) do
                         local skinData = catData[skinName]
                         
                         if type(skinData) == "table" then
                             if skinData.Texture or skinData.Mesh or skinData.Sound or skinData.Value then
                                 -- Leaf items
                                 lua_str = lua_str .. string.format('            ["%s"] = {', skinName)
                                 if skinData.Texture then lua_str = lua_str .. 'Texture="'..skinData.Texture..'", ' end
                                 if skinData.Mesh then lua_str = lua_str .. 'Mesh="'..skinData.Mesh..'", ' end
                                 if skinData.Sound then lua_str = lua_str .. 'Sound="'..skinData.Sound..'", ' end
                                 if skinData.Value then lua_str = lua_str .. 'Value="'..skinData.Value..'", ' end
                                 lua_str = lua_str .. "},\n"
                             else
                                 -- Sub-folder items (Skins inside category)
                                 lua_str = lua_str .. string.format('            ["%s"] = {\n', skinName)
                                 
                                 local items = {}
                                 for k in pairs(skinData) do table.insert(items, k) end
                                 table.sort(items)
                                 
                                 for _, itemName in ipairs(items) do
                                     local itemData = skinData[itemName]
                                     if type(itemData) == "table" and (itemData.Texture or itemData.Mesh or itemData.Sound or itemData.Value) then
                                         lua_str = lua_str .. string.format('                ["%s"] = {', itemName)
                                         if itemData.Texture then lua_str = lua_str .. 'Texture="'..itemData.Texture..'", ' end
                                         if itemData.Mesh then lua_str = lua_str .. 'Mesh="'..itemData.Mesh..'", ' end
                                         if itemData.Sound then lua_str = lua_str .. 'Sound="'..itemData.Sound..'", ' end
                                         if itemData.Value then lua_str = lua_str .. 'Value="'..itemData.Value..'", ' end
                                         lua_str = lua_str .. "},\n"
                                     end
                                 end
                                 lua_str = lua_str .. "            },\n"
                             end
                         end
                    end
                    lua_str = lua_str .. "        },\n"
                end
            end
        end
        lua_str = lua_str .. "    },\n"
    end
    lua_str = lua_str .. "}"
    
    return table.concat(lines, "\n") .. "\n\n" .. lua_str
end

local success, result = pcall(dump_all)
local filename = "DaHood_ULTIMATE_Dump_V3.txt"

if success then
    if writefile then
        writefile(filename, result)
        print("Details saved to " .. filename)
    else
        print(result)
    end
    if setclipboard then setclipboard(result) end
else
    warn("Dump error: " .. tostring(result))
end
