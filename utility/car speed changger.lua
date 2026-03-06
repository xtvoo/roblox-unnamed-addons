-- Da Hood Vehicle Tuner v2 (Unnamed Addon with UI)
-- workspace/unnamed/lua/dh_vehicle_tuner.lua

local api = api

-- ========= UI SETUP =========
local VehiclesFolder = workspace:WaitForChild("Vehicles")

-- Default config
local Config = {
    Enabled = false,
    TargetVehicle = "EagleSkaterSparkly",
    Speed = 80,
    Torque = 50,
    Jump = 0,
    AntiReset = true,
}

-- Create UI Tab
local tabs = {
    main = api:GetTab("misc") or api:AddTab("misc")
}

-- Main groupbox
local mainBox = tabs.main:AddLeftGroupbox("Vehicle Settings")

-- Enable toggle
mainBox:AddToggle("vt_enabled", {
    Text = "Enable Vehicle Tuner",
    Default = false,
    Callback = function(value)
        Config.Enabled = value
        if value then
            api:notify("Vehicle tuner enabled", 2)
            tune_all_vehicles()
        else
            api:notify("Vehicle tuner disabled", 2)
        end
    end
})

-- Vehicle name input
mainBox:AddInput("vt_vehicle", {
    Text = "Vehicle Name",
    Default = "EagleSkaterSparkly",
    Placeholder = "Enter vehicle name...",
    Callback = function(value)
        Config.TargetVehicle = value
        if Config.Enabled then
            tune_all_vehicles()
        end
    end
})

-- Speed slider
mainBox:AddSlider("vt_speed", {
    Text = "Speed",
    Min = 10,
    Max = 300,
    Default = 80,
    Rounding = 0,
    Callback = function(value)
        Config.Speed = value
        if Config.Enabled then
            tune_all_vehicles()
        end
    end
})

-- Torque slider
mainBox:AddSlider("vt_torque", {
    Text = "Torque",
    Min = 10,
    Max = 200,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        Config.Torque = value
        if Config.Enabled then
            tune_all_vehicles()
        end
    end
})

-- Jump slider
mainBox:AddSlider("vt_jump", {
    Text = "Jump Power",
    Min = 0,
    Max = 200,
    Default = 0,
    Rounding = 0,
    Callback = function(value)
        Config.Jump = value
        if Config.Enabled then
            tune_all_vehicles()
        end
    end
})

-- Anti-reset toggle
mainBox:AddToggle("vt_antireset", {
    Text = "Anti-Reset Protection",
    Default = true,
    Tooltip = "Prevents game from resetting your attributes",
    Callback = function(value)
        Config.AntiReset = value
    end
})

-- Info groupbox
local infoBox = tabs.main:AddRightGroupbox("Info & Presets")

infoBox:AddLabel("Tuner v2.0")
infoBox:AddDivider()
infoBox:AddLabel("Quick Presets:")

infoBox:AddButton("Legit Mode", function()
    api:getuiobject("vt_speed"):SetValue(80)
    api:getuiobject("vt_torque"):SetValue(50)
    api:getuiobject("vt_jump"):SetValue(0)
    api:notify("Legit preset applied", 2)
end)

infoBox:AddButton("Fast Mode", function()
    api:getuiobject("vt_speed"):SetValue(150)
    api:getuiobject("vt_torque"):SetValue(100)
    api:getuiobject("vt_jump"):SetValue(50)
    api:notify("Fast preset applied", 2)
end)

infoBox:AddButton("Max Speed", function()
    api:getuiobject("vt_speed"):SetValue(300)
    api:getuiobject("vt_torque"):SetValue(200)
    api:getuiobject("vt_jump"):SetValue(200)
    api:notify("Max speed preset applied", 2)
end)

infoBox:AddDivider()
infoBox:AddButton("Tune Current Vehicle", function()
    local vehicle = api:getcurrentvehicle()
    if vehicle then
        tune_vehicle(vehicle)
        api:notify("Tuned " .. vehicle.Name, 2)
    else
        api:notify("Not in a vehicle", 2)
    end
end)

-- ========= CORE LOGIC =========

local function tune_skin(skin)
    if not skin or not skin.GetAttribute then return end

    local changed = false
    
    if skin:GetAttribute("Speed") ~= nil then
        skin:SetAttribute("Speed", Config.Speed)
        changed = true
    end

    if skin:GetAttribute("Torque") ~= nil then
        skin:SetAttribute("Torque", Config.Torque)
        changed = true
    end

    if skin:GetAttribute("Jump") ~= nil then
        skin:SetAttribute("Jump", Config.Jump)
        changed = true
    end
    
    return changed
end

local function tune_vehicle(model)
    if not Config.Enabled then return end
    if not model or not model:IsA("Model") then return end
    
    -- If target vehicle is set, only tune that vehicle
    if Config.TargetVehicle ~= "" and not string.find(model.Name, Config.TargetVehicle) then 
        return 
    end

    local skin = model:FindFirstChild("Skin")
    if skin then
        local success = tune_skin(skin)
        if success then
            print("[Vehicle Tuner] Tuned:", model.Name)
        end
    end
end

function tune_all_vehicles()
    if not Config.Enabled then return end
    
    for _, v in ipairs(VehiclesFolder:GetChildren()) do
        tune_vehicle(v)
    end
end

-- Hook attribute protection
local protectedSkins = {}

local function hook_attribute_protection(skin)
    if not skin or not skin.GetAttributeChangedSignal then return end
    if protectedSkins[skin] then return end
    
    protectedSkins[skin] = true

    local function protect_attr(attrName, getConfigValue)
        api:addconnection(
            skin:GetAttributeChangedSignal(attrName):Connect(function()
                if not Config.Enabled or not Config.AntiReset then return end
                
                local desired = getConfigValue()
                local current = skin:GetAttribute(attrName)
                
                if current ~= desired then
                    task.wait(0.1)
                    skin:SetAttribute(attrName, desired)
                    print("[Vehicle Tuner] Re-applied", attrName, "to", desired)
                end
            end)
        )
    end

    if skin:GetAttribute("Speed") then
        protect_attr("Speed", function() return Config.Speed end)
    end
    
    if skin:GetAttribute("Torque") then
        protect_attr("Torque", function() return Config.Torque end)
    end
    
    if skin:GetAttribute("Jump") then
        protect_attr("Jump", function() return Config.Jump end)
    end
end

-- Tune existing vehicles on load
for _, v in ipairs(VehiclesFolder:GetChildren()) do
    tune_vehicle(v)
    
    local s = v:FindFirstChild("Skin")
    if s then
        hook_attribute_protection(s)
    end
end

-- Monitor new vehicles spawning
api:addconnection(VehiclesFolder.ChildAdded:Connect(function(child)
    task.wait(0.5)
    tune_vehicle(child)
    
    local s = child:FindFirstChild("Skin")
    if s then
        hook_attribute_protection(s)
    end
end))

-- Tune vehicle when you enter it
api:onevent("localplayerrodevehicle", function(vehicle)
    if vehicle and Config.Enabled then
        task.wait(0.2)
        tune_vehicle(vehicle)
        api:notify("Tuned vehicle", 1)
    end
end)

-- ========= CLEANUP =========
api:onevent("unload", function()
    api:notify("Vehicle tuner unloaded", 2)
end)

api:notify("Vehicle tuner loaded!", 3)
