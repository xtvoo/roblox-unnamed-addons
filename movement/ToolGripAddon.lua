-- ToolGripAddon.lua
-- Unnamed Addon for Tool Grip Manipulation
-- Location: da hood/lua/scripts/ToolGripAddon.lua
-- Features: Presets, Real-time Replication, Visual Debugger

api:set_lua_name("ToolGripAddon")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    Enabled = false,
    Method = "Hybrid (Best)", -- Hits both Prop and Joint
    Preset = "Custom",
    Smoothness = 10,
    X = 0, Y = 0, Z = 0,
    RotX = 0, RotY = 0, RotZ = 0
}

local GripCache = setmetatable({}, {__mode = "k"})
local currentTool = nil
local StatusMsg = "Idle"

-- UI Setup
local Tab = api:AddTab("Tool Grip Plus")
local Groupbox = Tab:AddLeftGroupbox("Controls")
local StatusLabel = Groupbox:AddLabel("Status: Idle")

-- Helper: Disconnect Fake Position
local function nukeConflictingScripts()
    -- Try to disable via Toggles
    if getgenv().Toggles and getgenv().Toggles.GripEnabled and getgenv().Toggles.GripEnabled.Value then
        getgenv().Toggles.GripEnabled:SetValue(false)
        api:notify("Conflicting 'Seth Grip' Disabled", 3)
    end
    -- Try to disconnect Handler connection directly if possible
    if getgenv().Handler and getgenv().Handler.Disconnect then
        pcall(function() getgenv().Handler:Disconnect("Grip Tools", true) end)
    end
end

-- Helper: Get Base
local function getStartGrip(tool)
    if not GripCache[tool] then
        GripCache[tool] = tool.Grip
    end
    return GripCache[tool]
end

-- Presets Logic
local Presets = {
    ["Custom"] = {0,0,0, 0,0,0},
    ["Forward"] = {0, 0, -1, 0, 0, 0},
    ["Upside Down"] = {0, 0, 0, 0, 0, 180},
    ["Sideways"] = {0, 0, 0, 0, 0, 90},
    ["Self-Stab"] = {-1, 0, 0, 0, 90, 0},
    ["Giant Reach"] = {0, 0, -4, 0, 0, 0},
}

local function applyPreset(name)
    local p = Presets[name]
    if not p then return end
    if name ~= "Custom" then
        -- Set sliders (visual only, real values used in loop)
        -- We won't update UI objects to avoid loop, just set internal config
        Config.X, Config.Y, Config.Z = p[1], p[2], p[3]
        Config.RotX, Config.RotY, Config.RotZ = p[4], p[5], p[6]
        -- Update UI Sliders
        api:get_ui_object("GripX"):SetValue(p[1])
        api:get_ui_object("GripY"):SetValue(p[2])
        api:get_ui_object("GripZ"):SetValue(p[3])
    end
end

-- UI Elements
Groupbox:AddToggle("GripEnable", {
    Text = "Enable Grip Mod",
    Default = false,
    Callback = function(Value)
        Config.Enabled = Value
        if Value then
            nukeConflictingScripts()
            StatusMsg = "Active"
        else
            StatusMsg = "Disabled"
            -- Restore
            if currentTool then
                local base = getStartGrip(currentTool)
                currentTool.Grip = base
                local char = LocalPlayer.Character
                if char then
                    local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
                    if arm and arm:FindFirstChild("RightGrip") then
                        arm.RightGrip.C1 = base
                    end
                end
            end
        end
        StatusLabel:SetText("Status: " .. StatusMsg)
    end
})

Groupbox:AddDropdown("PresetDrop", {
    Values = {"Custom", "Forward", "Upside Down", "Sideways", "Self-Stab", "Giant Reach"},
    Default = "Custom",
    Multi = false,
    Text = "Preset Pose",
    Callback = function(Value)
        Config.Preset = Value
        applyPreset(Value)
    end
})

Groupbox:AddSlider("Smoothness", {
    Text = "Smoothness (Speed)",
    Default = 15, Min = 1, Max = 50, Rounding = 1,
    Callback = function(Value) Config.Smoothness = Value end
})

local function addSlider(id, text, key, min, max)
    Groupbox:AddSlider(id, {
        Text = text,
        Default = 0, Min = min, Max = max, Rounding = 1,
        Callback = function(Value)
            Config[key] = Value
            if Config.Preset ~= "Custom" and Config.Enabled then
                 Config.Preset = "Custom" -- Switch back to custom if modified
                 -- api:get_ui_object("PresetDrop"):SetValue("Custom") -- If supported
            end
        end
    })
end

addSlider("GripX", "Offset X", "X", -10, 10)
addSlider("GripY", "Offset Y", "Y", -10, 10)
addSlider("GripZ", "Offset Z", "Z", -10, 10)

Groupbox:AddButton("Reset Base Grip", function()
    if currentTool then
        currentTool.Grip = CFrame.new(0,0,0) -- Try identity
        GripCache[currentTool] = nil -- Clear cache
        getStartGrip(currentTool) -- Re-cache current
        api:notify("Base Grip Reset", 2)
    end
end)

-- Update Loop
RunService:BindToRenderStep("GripUpdateLoop", Enum.RenderPriority.Camera.Value, function(dt)
    if not Config.Enabled then return end
    
    local tool = Config.ToolOverride or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool"))
    
    if tool ~= currentTool then
        currentTool = tool
        if tool then
            nukeConflictingScripts() -- Ensure clean start on equip
            getStartGrip(tool)
            StatusMsg = "Tracking: " .. tool.Name
        else
            StatusMsg = "Waiting for Tool..."
        end
        StatusLabel:SetText("Status: " .. StatusMsg)
    end

    if not currentTool then return end

    local baseGrip = getStartGrip(currentTool)
    
    -- Calculate Target
    local targetOffset = CFrame.new(Config.X, Config.Y, Config.Z) * 
                         CFrame.Angles(math.rad(Config.RotX), math.rad(Config.RotY), math.rad(Config.RotZ))
    
    local currentGrip = currentTool.Grip
    local targetGrip = baseGrip * targetOffset
    
    local alpha = math.clamp(dt * Config.Smoothness, 0, 1)
    local newGrip = currentGrip:Lerp(targetGrip, alpha)
    
    -- Apply Hybrid (Prop + Joint)
    currentTool.Grip = newGrip
    
    local char = LocalPlayer.Character
    if char then
        local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        if arm and arm:FindFirstChild("RightGrip") then
            arm.RightGrip.C1 = newGrip
        end
    end
end)

api:on_event("unload", function()
    RunService:UnbindFromRenderStep("GripUpdateLoop")
    api:notify("Tool Grip Unloaded", 2)
end)

StatusLabel:SetText("Status: Script Loaded")
api:notify("Tool Grip Plus Loaded", 3)
