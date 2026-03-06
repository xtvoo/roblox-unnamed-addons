-- Da Hood Skin Changer - Unnamed Addon
-- Dynamically loads ALL skins from the game's SkinModules

api:set_lua_name("SkinChanger")

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ===== GET SKIN MODULES =====
local SkinModules = ReplicatedStorage:FindFirstChild("SkinModules")
local MeshesFolder = SkinModules and SkinModules:FindFirstChild("Meshes")

if not MeshesFolder then
    api:notify("SkinModules not found!", 3)
    return
end

-- ===== DYNAMICALLY BUILD SKIN LIST =====
local AllSkins = {}
local SkinData = {}

for _, skinFolder in ipairs(MeshesFolder:GetChildren()) do
    if skinFolder:IsA("Folder") then
        local skinName = skinFolder.Name
        table.insert(AllSkins, skinName)
        SkinData[skinName] = {}
        
        for _, mesh in ipairs(skinFolder:GetChildren()) do
            if mesh:IsA("MeshPart") or mesh:IsA("Part") or mesh:IsA("Model") then
                SkinData[skinName][mesh.Name] = mesh
            end
        end
    end
end

table.sort(AllSkins)

-- ===== WEAPON MAPPING =====
local WeaponMapping = {
    ["Rev"] = "[Revolver]", ["rev"] = "[Revolver]", ["Revolver"] = "[Revolver]",
    ["ElectricRevolver"] = "[Revolver]", ["RevolverGhost"] = "[Revolver]",
    ["DB"] = "[Double-Barrel SG]", ["db"] = "[Double-Barrel SG]",
    ["ElectricDB"] = "[Double-Barrel SG]", ["DoubleBGhost"] = "[Double-Barrel SG]",
    ["RPG"] = "[RPG]", ["rpg"] = "[RPG]", ["Bazooka"] = "[RPG]",
    ["ElectricRPG"] = "[RPG]", ["RPGGhost"] = "[RPG]",
    ["Rocket"] = "[RPG]", ["Launcher"] = "[RPG]", ["launcher"] = "[RPG]",
    ["FT"] = "[Flamethrower]", ["ft"] = "[Flamethrower]", ["Flamethrower"] = "[Flamethrower]",
    ["ElectricFT"] = "[Flamethrower]", ["FlamethrowerGhost"] = "[Flamethrower]",
    ["Tac"] = "[TacticalShotgun]", ["Tact"] = "[TacticalShotgun]", ["tact"] = "[TacticalShotgun]",
    ["ElectricTac"] = "[TacticalShotgun]", ["TacticalShotgunGhost"] = "[TacticalShotgun]",
    ["SG"] = "[Shotgun]", ["Shotgun"] = "[Shotgun]",
    ["ElectricShotgun"] = "[Shotgun]", ["ShotgunGhost"] = "[Shotgun]",
    ["AK"] = "[AK47]", ["AK47"] = "[AK47]",
    ["ElectricAK"] = "[AK47]", ["AK47Ghost"] = "[AK47]",
    ["AR"] = "[AR]", ["Rifle"] = "[AR]", ["rifle"] = "[AR]",
    ["ElectricAR"] = "[AR]", ["ElectricRifle"] = "[AR]", ["ARGhost"] = "[AR]", ["RifleGhost"] = "[AR]",
    ["AUG"] = "[AUG]", ["Aug"] = "[AUG]",
    ["ElectricAUG"] = "[AUG]", ["AUGGhost"] = "[AUG]",
    ["SMG"] = "[SMG]", ["smg"] = "[SMG]", ["Uzi"] = "[SMG]",
    ["ElectricSMG"] = "[SMG]", ["SMGGhost"] = "[SMG]",
    ["LMG"] = "[LMG]", ["lmg"] = "[LMG]",
    ["ElectricLMG"] = "[LMG]", ["LMGGhost"] = "[LMG]",
    ["P90"] = "[P90]",
    ["ElectricP90"] = "[P90]", ["P90Ghost"] = "[P90]",
    ["Drum"] = "[DrumGun]", ["DrumGun"] = "[DrumGun]",
    ["ElectricDrum"] = "[DrumGun]", ["DrumgunGhost"] = "[DrumGun]",
    ["Glock"] = "[Glock]",
    ["ElectricGlock"] = "[Glock]", ["GlockGhost"] = "[Glock]",
    ["Silencer"] = "[Silencer]",
}

-- ===== CONFIG =====
local Config = {
    Enabled = false,
    SelectedSkin = AllSkins[1] or "Electric",
    AutoApply = true,
    ApplyDelay = 0.1,
    Weapons = {
        Revolver = true,
        DoubleBarrel = true,
        RPG = true,
        Flamethrower = true,
        TacticalShotgun = true,
        Shotgun = true,
        AK47 = true,
        AR = true,
        AUG = true,
        SMG = true,
        LMG = true,
        P90 = true,
        DrumGun = true,
        Glock = true,
        Silencer = true,
    }
}

local OriginalTextures = {}

-- ===== CORE FUNCTIONS =====
local function GetWeaponDefaultPart(weapon)
    return weapon:FindFirstChild("Default") or weapon:FindFirstChild("Handle")
end

local function IsWeaponEnabled(weaponName)
    local cleanName = weaponName:gsub("%[", ""):gsub("%]", ""):gsub("-", ""):gsub(" ", "")
    for key, enabled in pairs(Config.Weapons) do
        if cleanName:lower():find(key:lower()) then
            return enabled
        end
    end
    return true
end

local function ApplySkinToWeapon(weapon, skinName)
    if not IsWeaponEnabled(weapon.Name) then return false end
    
    local skinMeshes = SkinData[skinName]
    if not skinMeshes then return false end
    
    local weaponName = weapon.Name
    
    for meshName, meshTemplate in pairs(skinMeshes) do
        local mappedWeapon = WeaponMapping[meshName]
        if mappedWeapon == weaponName then
            local defaultPart = GetWeaponDefaultPart(weapon)
            if defaultPart and meshTemplate:IsA("MeshPart") then
                if not OriginalTextures[weaponName] then
                    OriginalTextures[weaponName] = {
                        MeshId = defaultPart.MeshId,
                        TextureID = defaultPart.TextureID,
                    }
                end
                
                pcall(function()
                    defaultPart.TextureID = meshTemplate.TextureID
                    if meshTemplate.MeshId and meshTemplate.MeshId ~= "" then
                        defaultPart.MeshId = meshTemplate.MeshId
                    end
                end)
                return true
            end
        end
    end
    return false
end

local function ApplyAllSkins()
    local char = LocalPlayer.Character
    if not char then return 0 end
    
    local applied = 0
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") or (item.Name:match("^%[") and item.Name:match("%]$")) then
            if ApplySkinToWeapon(item, Config.SelectedSkin) then
                applied = applied + 1
            end
        end
    end
    return applied
end

local function RestoreOriginals()
    local char = LocalPlayer.Character
    if not char then return end
    
    for weaponName, original in pairs(OriginalTextures) do
        local weapon = char:FindFirstChild(weaponName)
        if weapon then
            local defaultPart = GetWeaponDefaultPart(weapon)
            if defaultPart then
                pcall(function()
                    defaultPart.MeshId = original.MeshId
                    defaultPart.TextureID = original.TextureID
                end)
            end
        end
    end
end

-- ===== UI SETUP =====
local tab = api:AddTab("Skins")

-- ===== MAIN GROUP =====
local mainGroup = tab:AddLeftGroupbox("Skin Changer")

mainGroup:AddToggle("skin_enabled", {
    Text = "Enable Skin Changer",
    Default = false,
    Tooltip = "Toggle skin changer on/off",
    Callback = function(value)
        Config.Enabled = value
        if value then
            api:notify("Skin Changer Enabled", 2)
        else
            RestoreOriginals()
            api:notify("Skin Changer Disabled", 2)
        end
    end
})

mainGroup:AddToggle("skin_auto_apply", {
    Text = "Auto Apply",
    Default = true,
    Tooltip = "Automatically apply skins each frame",
    Callback = function(value)
        Config.AutoApply = value
    end
})

mainGroup:AddDivider()

mainGroup:AddDropdown("skin_select", {
    Text = "Select Skin",
    Default = AllSkins[1] or "Electric",
    Values = AllSkins,
    Tooltip = "Choose skin (" .. #AllSkins .. " available)",
    Callback = function(value)
        Config.SelectedSkin = value
        if Config.Enabled then
            ApplyAllSkins()
            api:notify("Skin: " .. value, 2)
        end
    end
})

mainGroup:AddSlider("skin_delay", {
    Text = "Apply Delay",
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Config.ApplyDelay = value
    end
})

mainGroup:AddDivider()

mainGroup:AddButton({
    Text = "Apply Now",
    Func = function()
        local count = ApplyAllSkins()
        api:notify("Applied to " .. count .. " weapons", 2)
    end
})

mainGroup:AddButton({
    Text = "Restore Defaults",
    Func = function()
        RestoreOriginals()
        api:notify("Restored original skins", 2)
    end
})

-- ===== QUICK SELECT =====
local quickGroup = tab:AddRightGroupbox("Quick Select")

local popularSkins = {"Electric", "Shadow", "Brainrot", "Dragon", "gothic", 
                      "Halloween", "XMAS", "Love", "Soul", "Cartoon", "Aqua", "Cat"}

for _, skinName in ipairs(popularSkins) do
    if table.find(AllSkins, skinName) then
        quickGroup:AddButton({
            Text = skinName,
            Func = function()
                Config.SelectedSkin = skinName
                if Config.Enabled then ApplyAllSkins() end
                api:notify("Selected: " .. skinName, 1)
            end
        })
    end
end

-- ===== WEAPON TOGGLES =====
local weaponGroup = tab:AddLeftGroupbox("Weapons")

local weapons = {
    {name = "Revolver", key = "Revolver"},
    {name = "Double Barrel", key = "DoubleBarrel"},
    {name = "RPG", key = "RPG"},
    {name = "Flamethrower", key = "Flamethrower"},
    {name = "Tactical Shotgun", key = "TacticalShotgun"},
    {name = "Shotgun", key = "Shotgun"},
    {name = "AK47", key = "AK47"},
    {name = "AR", key = "AR"},
}

for _, weapon in ipairs(weapons) do
    weaponGroup:AddToggle("weapon_" .. weapon.key, {
        Text = weapon.name,
        Default = true,
        Callback = function(value)
            Config.Weapons[weapon.key] = value
        end
    })
end

-- ===== MORE WEAPONS =====
local weaponGroup2 = tab:AddRightGroupbox("More Weapons")

local moreWeapons = {
    {name = "AUG", key = "AUG"},
    {name = "SMG", key = "SMG"},
    {name = "LMG", key = "LMG"},
    {name = "P90", key = "P90"},
    {name = "Drum Gun", key = "DrumGun"},
    {name = "Glock", key = "Glock"},
    {name = "Silencer", key = "Silencer"},
}

for _, weapon in ipairs(moreWeapons) do
    weaponGroup2:AddToggle("weapon_" .. weapon.key, {
        Text = weapon.name,
        Default = true,
        Callback = function(value)
            Config.Weapons[weapon.key] = value
        end
    })
end

-- ===== INFO =====
local infoGroup = tab:AddRightGroupbox("Info")
infoGroup:AddLabel("Total Skins: " .. #AllSkins)
infoGroup:AddLabel("Full sets: Electric, Shadow")

-- ===== MAIN LOOP =====
local lastApply = 0
api:add_connection(RunService.RenderStepped:Connect(function()
    if Config.Enabled and Config.AutoApply then
        local now = tick()
        if now - lastApply >= Config.ApplyDelay then
            lastApply = now
            ApplyAllSkins()
        end
    end
end))

-- ===== CLEANUP =====
api:on_event("unload", function()
    RestoreOriginals()
    api:notify("Skin Changer unloaded", 2)
end)

-- ===== STARTUP =====
api:notify("Skin Changer loaded! (" .. #AllSkins .. " skins)", 2)
