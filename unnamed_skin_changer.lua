api:set_lua_name("UltimateSkinChanger")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- DATA STRUCTURES
local SkinDatabase = {} 
local PlayerSkins = {} 
local SelectedWeapon = "[Revolver]" 
local IsSkinChangerEnabled = false

-- WEAPON MAPPING
local WeaponMapping = {
    -- GUNS
    ["Rev"] = "[Revolver]", ["Revolver"] = "[Revolver]",
    ["DB"] = "[Double-Barrel SG]", ["DoubleBarrel"] = "[Double-Barrel SG]",
    ["RPG"] = "[RPG]", ["Rocket"] = "[RPG]", ["Launcher"] = "[RPG]",
    ["FT"] = "[Flamethrower]", ["Flamethrower"] = "[Flamethrower]",
    ["Tac"] = "[TacticalShotgun]", ["TacticalShotgun"] = "[TacticalShotgun]",
    ["SG"] = "[Shotgun]", ["Shotgun"] = "[Shotgun]",
    ["AK"] = "[AK47]", ["AK47"] = "[AK47]",
    ["AR"] = "[AR]", ["Rifle"] = "[AR]",
    ["AUG"] = "[AUG]",
    ["SMG"] = "[SMG]", ["Uzi"] = "[SMG]",
    ["LMG"] = "[LMG]",
    ["P90"] = "[P90]",
    ["Drum"] = "[DrumGun]", ["DrumGun"] = "[DrumGun]",
    ["Glock"] = "[Glock]",
    ["Silencer"] = "[Silencer]",
    ["SilencerAR"] = "[SilencerAR]",
    
    -- MELEE / ITEMS
    ["Knife"] = "[Knife]",
    ["Wallet"] = "[Wallet]", 
}

-- HELPER: Get Asset IDs from an Object (INCLUDING SCALE/OFFSET)
local function GetAssetIDs(obj)
    local data = {}
    if obj:IsA("MeshPart") then
        if obj.TextureID ~= "" then data.Texture = obj.TextureID end
        if obj.MeshId ~= "" then data.Mesh = obj.MeshId end
    elseif obj:IsA("Part") or obj:IsA("UnionOperation") then
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("SpecialMesh") then
                if child.TextureId ~= "" then data.Texture = child.TextureId end
                if child.MeshId ~= "" then data.Mesh = child.MeshId end
                
                -- CRITICAL: Capture Scale and Offset for crazy skins like Ban Hammer
                data.Scale = child.Scale
                data.Offset = child.Offset
                data.VertexColor = child.VertexColor
                
            elseif child:IsA("Texture") or child:IsA("Decal") then
                if child.Texture ~= "" then data.Texture = child.Texture end
            end
        end
    elseif obj:IsA("Sound") then
        if obj.SoundId ~= "" then data.Sound = obj.SoundId end
    elseif obj:IsA("StringValue") or obj:IsA("IntValue") then
        local str = tostring(obj.Value)
        if str:match("rbxassetid") or str:match("%d+") then
             data.Value = str
        end
    end
    return next(data) and data or nil
end

-- HELPER: Deep Scan Function
local function ScanFolderForAssets(folder, collection)
    for _, child in ipairs(folder:GetChildren()) do
        local ids = GetAssetIDs(child)
        if ids then
            for k, v in pairs(ids) do collection[k] = v end
        end
        if child:IsA("Folder") or child:IsA("Model") then
             ScanFolderForAssets(child, collection)
        end
    end
end

-- CORE: Asset Loading Logic
local function LoadAllSkins()
    SkinDatabase = {}
    local Modules = ReplicatedStorage:FindFirstChild("SkinModules")
    if not Modules then return end

    local function RegisterSkin(ToolName, SkinName, AssetData)
        if not SkinDatabase[ToolName] then SkinDatabase[ToolName] = {} end
        if not SkinDatabase[ToolName][SkinName] then
            SkinDatabase[ToolName][SkinName] = AssetData
        else
            for k,v in pairs(AssetData) do SkinDatabase[ToolName][SkinName][k] = v end
        end
    end

    -- 1. Scan KNIVES
    if Modules:FindFirstChild("Knives") then
        for _, skin in ipairs(Modules.Knives:GetChildren()) do
             local assetData = {}
             -- Look for "Handle" specifically to get correct Mesh/Scale
             local handle = skin:FindFirstChild("Handle") or skin:FindFirstChild("Default")
             if handle then
                 local ids = GetAssetIDs(handle)
                 if ids then assetData = ids end
             else
                 -- Fallback to deep scan if no handle found
                 ScanFolderForAssets(skin, assetData)
             end

             if next(assetData) then
                 RegisterSkin("[Knife]", skin.Name, assetData)
             end
        end
    end

    -- 2. Scan WALLETS
    if Modules:FindFirstChild("Wallets") then
        for _, skin in ipairs(Modules.Wallets:GetChildren()) do
             local assetData = {}
             local handle = skin:FindFirstChild("Handle") or skin:FindFirstChild("Default")
             if handle then
                 local ids = GetAssetIDs(handle)
                 if ids then assetData = ids end
             else
                 ScanFolderForAssets(skin, assetData)
             end
             
             if next(assetData) then
                 RegisterSkin("[Wallet]", skin.Name, assetData)
             end
        end
    end

    -- 3. Scan MESHES (Guns)
    if Modules:FindFirstChild("Meshes") then
        for _, skinFolder in ipairs(Modules.Meshes:GetChildren()) do
            local SkinName = skinFolder.Name
            for _, gunFile in ipairs(skinFolder:GetChildren()) do
                local ToolName = nil
                if WeaponMapping[gunFile.Name] then
                    ToolName = WeaponMapping[gunFile.Name]
                else
                    for key, mappedName in pairs(WeaponMapping) do
                        if gunFile.Name:lower():find(key:lower()) then
                            ToolName = mappedName
                            break
                        end
                    end
                end
                
                if ToolName then
                    local assetData = {}
                    ScanFolderForAssets(gunFile, assetData)
                    if next(assetData) then
                        RegisterSkin(ToolName, SkinName, assetData)
                    end
                end
            end
        end
    end
    
    -- 4. Scan SOUNDS
    local SkinAssets = ReplicatedStorage:FindFirstChild("SkinAssets")
    if SkinAssets and SkinAssets:FindFirstChild("GunShootSounds") then
        for _, gunFolder in ipairs(SkinAssets.GunShootSounds:GetChildren()) do
             local ToolName = WeaponMapping[gunFolder.Name] or "["..gunFolder.Name.."]"
             for _, skinVal in ipairs(gunFolder:GetChildren()) do
                 local SkinName = skinVal.Name
                 local soundId = nil
                 if skinVal:IsA("Sound") then soundId = skinVal.SoundId 
                 elseif skinVal:IsA("StringValue") then soundId = skinVal.Value end
                 
                 if soundId and ToolName then
                     RegisterSkin(ToolName, SkinName, {Sound = soundId})
                 end
             end
        end
    end

    for tool, skins in pairs(SkinDatabase) do
        skins["Default"] = {IsDefault = true}
    end
end

LoadAllSkins()

-- UI Setup
local Tab = api:AddTab("Ultimate Skin Changer")
local Group = Tab:AddLeftGroupbox("Loadout")

local WeaponList = {}
for k in pairs(SkinDatabase) do table.insert(WeaponList, k) end
table.sort(WeaponList)

local WeaponDropdown = Group:AddDropdown("WeaponSelect", {
    Values = WeaponList,
    Default = 1,
    Multi = false,
    Text = "Weapon",
    Callback = function(Val)
        SelectedWeapon = Val
        local skins = {}
        if SkinDatabase[SelectedWeapon] then
            for k in pairs(SkinDatabase[SelectedWeapon]) do table.insert(skins, k) end
            table.sort(skins)
        end
        
        local dropdown = api:get_ui_object("SkinSelect")
        if dropdown then dropdown:SetValues(skins) end
        
        local currentSkin = PlayerSkins[SelectedWeapon] or "Default"
        if dropdown then dropdown:SetValue(currentSkin) end
    end
})

Group:AddDropdown("SkinSelect", {
    Values = {"Default"}, 
    Default = 1,
    Multi = false,
    Text = "Skin",
    Callback = function(Val)
        if SelectedWeapon then
            PlayerSkins[SelectedWeapon] = Val
        end
    end
})

Group:AddToggle("EnableSkins", {
    Text = "Enable Skin Changer",
    Default = false,
    Callback = function(Val)
        IsSkinChangerEnabled = Val
    end
})

Group:AddButton({
    Text = "Refresh Assets", 
    Func = function() 
        LoadAllSkins() 
        api:notify("Assets Refreshed!", 3)
    end
})

-- CORE LOOP
RunService.BindToRenderStep(RunService, "UltimateSkinApplier", 0, function()
    if not IsSkinChangerEnabled then return end
    
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer or not LocalPlayer.Character then return end
    
    for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") and PlayerSkins[tool.Name] then
            local desiredSkinName = PlayerSkins[tool.Name]
            if desiredSkinName ~= "Default" then 
                local data = SkinDatabase[tool.Name][desiredSkinName]
                if data then
                    local parts = {tool:FindFirstChild("Handle"), tool:FindFirstChild("Default")}
                    for _, p in ipairs(tool:GetChildren()) do 
                        if p:IsA("MeshPart") then table.insert(parts, p) end
                    end
                    
                    for _, part in ipairs(parts) do
                        if part then
                            -- Apply Texture
                            if data.Texture then
                                if part:IsA("MeshPart") then 
                                    if part.TextureID ~= data.Texture then part.TextureID = data.Texture end
                                elseif part:FindFirstChildOfClass("SpecialMesh") then 
                                    part:FindFirstChildOfClass("SpecialMesh").TextureId = data.Texture
                                elseif part:FindFirstChildOfClass("Decal") then 
                                    part:FindFirstChildOfClass("Decal").Texture = data.Texture
                                end
                            end
                            
                            -- Apply Mesh & Transforms
                            if data.Mesh then
                                if part:IsA("MeshPart") then 
                                    if part.MeshId ~= data.Mesh and data.Mesh ~= "" then part.MeshId = data.Mesh end
                                elseif part:FindFirstChildOfClass("SpecialMesh") then 
                                    local m = part:FindFirstChildOfClass("SpecialMesh")
                                    if m.MeshId ~= data.Mesh and data.Mesh ~= "" then m.MeshId = data.Mesh end
                                    
                                    -- Apply Scale, Offset, VertexColor (Fixes Ban Hammer)
                                    if data.Scale and m.Scale ~= data.Scale then m.Scale = data.Scale end
                                    if data.Offset and m.Offset ~= data.Offset then m.Offset = data.Offset end
                                    if data.VertexColor and m.VertexColor ~= data.VertexColor then m.VertexColor = data.VertexColor end
                                end
                            end
                            
                            -- Apply Sound
                            if data.Sound then
                                for _, s in ipairs(part:GetDescendants()) do
                                    if s:IsA("Sound") and (s.Name:lower():find("fire") or s.Name:lower():find("shoot") or s.Name:lower():find("open")) then
                                        if s.SoundId ~= data.Sound then s.SoundId = data.Sound end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

api:notify("Ultimate Skin Changer: Fixed Meshes", 5)
