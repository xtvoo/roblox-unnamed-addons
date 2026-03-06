-- NaN Fling V2 (Expanded)
-- Requires 'api' global from the cheat environment
-- Merges 'stick glue' logic with NaN Fling capabilities

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI Setup via Unnamed API
local Tab = api:GetTab("Combat") or api:AddTab("Combat")
local Main_Tab = Tab:AddLeftGroupbox("Nan Fling - Main")
local Position_Tab = Tab:AddRightGroupbox("Nan Fling - Pos")
local Rotation_Tab = Tab:AddLeftGroupbox("Nan Fling - Rot")

-- Configuration
local GlueOffset = Vector3.new(0, 5, 0) -- Default Y=5 to prevent under-map
local GlueAngle = CFrame.Angles(-math.pi / 2, 0, 0) -- Default Face Down
local GlueEnabled = false
local IsFlinging = false

-- state for NaN Fling (0/0 = NaN, same as nanfling.iy)
local NanVector = Vector3.new(0/0, 0/0, 0/0)

-- Helper Functions
local function getTarget()
    -- Priority: Silent Aim
    if api.get_target then
         local t = api:get_target("silent")
         if t then return t end
    end
    -- Fallback: Cache
    local cache = api:get_target_cache("silent")
    if cache and cache.player then
        return cache.player
    end
    return nil
end

local function DisableGlue()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", nil)
            end
        end)
        -- Also restore platform stand if needed
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- Main Settings
Main_Tab:AddToggle("glue_enabled", {
    Text = "Glue Enabled",
    Default = false,
    Tooltip = "Enables the Ghost Glue mechanics",
    Callback = function(value)
        GlueEnabled = value
        if not value then
            DisableGlue()
        end
    end
}):AddKeyPicker('glue_keybind', {
    Default = 'G',
    Mode = 'Toggle',
    Text = 'Glue Toggle',
    NoUI = false,
})


Main_Tab:AddToggle("always_face_target", {
    Text = "Lock to Target Rotation",
    Default = false,
    Tooltip = "Stick to target's rotation (rotates with them)"
})

Main_Tab:AddDropdown("face_mode", {
    Text = "Rotation Mode",
    Default = 1,
    Values = {"Face Target", "Behind Target", "Side View Left", "Side View Right"},
    Tooltip = "Which direction to face relative to target"
})

Main_Tab:AddToggle("nan_fling_enabled", {
    Text = "NaN Fling (Max Velocity)",
    Default = false,
    Tooltip = "Continuously applies Infinite/NaN velocity to destroy target",
    Callback = function(val)
        IsFlinging = val
        if not val then
             -- Restore
             if LocalPlayer.Character then
                  local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                  if h then h.PlatformStand = false end
             end
        end
    end
}):AddKeyPicker('nan_fling_key', {
    Default = 'V',
    Mode = 'Toggle',
    Text = 'NaN Fling',
    NoUI = false,
})

-- Position Settings
Position_Tab:AddSlider("glue_offset_x", {
    Text = "X Offset", Default = 0, Min = -30, Max = 30, Rounding = 1, Compact = true,
    Callback = function(v) GlueOffset = Vector3.new(v, GlueOffset.Y, GlueOffset.Z) end
})
Position_Tab:AddSlider("glue_offset_y", {
    Text = "Y Offset", Default = 5, Min = -30, Max = 300, Rounding = 1, Compact = true,
    Callback = function(v) GlueOffset = Vector3.new(GlueOffset.X, v, GlueOffset.Z) end
})
Position_Tab:AddSlider("glue_offset_z", {
    Text = "Z Offset", Default = 0, Min = -30, Max = 30, Rounding = 1, Compact = true,
    Callback = function(v) GlueOffset = Vector3.new(GlueOffset.X, GlueOffset.Y, v) end
})

Position_Tab:AddLabel("Safe Offset: Y > 0 avoids void.")

-- Rotation Settings
Rotation_Tab:AddToggle("force_upright", {
    Text = "Force Upright",
    Default = true,
    Tooltip = "Keeps your character standing up regardless of target rotation"
})

Rotation_Tab:AddSlider("glue_pitch", {
    Text = "Pitch (X)", Default = -90, Min = -180, Max = 180, Rounding = 1, Compact = true,
    Callback = function(v) 
        local _, y, z = GlueAngle:ToEulerAnglesYXZ()
        GlueAngle = CFrame.Angles(math.rad(v), y, z)
    end
})
Rotation_Tab:AddSlider("glue_yaw", {
    Text = "Yaw (Y)", Default = 0, Min = -180, Max = 180, Rounding = 1, Compact = true,
    Callback = function(v) 
        local x, _, z = GlueAngle:ToEulerAnglesYXZ()
        GlueAngle = CFrame.Angles(x, math.rad(v), z)
    end
})

-- Position Presets
Position_Tab:AddDropdown("pos_preset", {
    Text = "Presets",
    Default = 1,
    Values = {"Default (Above)", "Same Position", "Below", "Front", "Behind"},
    Callback = function(val)
        if val == "Default (Above)" then
            Options['glue_offset_x']:SetValue(0)
            Options['glue_offset_y']:SetValue(5)
            Options['glue_offset_z']:SetValue(0)
        elseif val == "Same Position" then
            Options['glue_offset_x']:SetValue(0)
            Options['glue_offset_y']:SetValue(0)
            Options['glue_offset_z']:SetValue(0)
        elseif val == "Below" then
            Options['glue_offset_x']:SetValue(0)
            Options['glue_offset_y']:SetValue(-5)
            Options['glue_offset_z']:SetValue(0)
        elseif val == "Front" then
             Options['glue_offset_x']:SetValue(0)
             Options['glue_offset_y']:SetValue(0)
             Options['glue_offset_z']:SetValue(-3)
        elseif val == "Behind" then
             Options['glue_offset_x']:SetValue(0)
             Options['glue_offset_y']:SetValue(0)
             Options['glue_offset_z']:SetValue(3)
        end
    end
})

local VehicleDestroyTargets = {}

local function IsKnocked(player)
    if not player then return false end
    if not api or not api.get_status_cache then return false end
    local statusCache = api:get_status_cache(player)
    if not statusCache then return false end
    return statusCache["K.O"] == true
end

-- Main Logic Loop
RunService.Heartbeat:Connect(function()
    -- Check if we are Gluing (Persistent) OR Flinging (Toggle)
    -- We want to run the loop if Glue is Enabled OR NaN Fling is Enabled
    local glueActive = (GlueEnabled and Options['glue_keybind']:GetState())
    local flingActive = (Toggles['nan_fling_enabled'] and Toggles['nan_fling_enabled'].Value) or IsFlinging
    
    if not glueActive and not flingActive then return end

    local Target = getTarget()
    if not Target or not Target.Character or not Target.Character:FindFirstChild("HumanoidRootPart") then
         return 
    end
    
    local TargetRoot = Target.Character.HumanoidRootPart
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
    local MyHum = MyChar:FindFirstChildOfClass("Humanoid")
    if not MyRoot then return end

    -- Knocked Check: If they are knocked dont try to fling
    if IsKnocked(Target) then
         if MyHum then MyHum.PlatformStand = false end
         return
    end

    -- Vehicle Check
    local targetHum = Target.Character:FindFirstChildOfClass("Humanoid")
    local isOnVehicle = targetHum and targetHum.SeatPart ~= nil

    if isOnVehicle then
        -- Add target to ragebot to destroy vehicle
        local rageTargetUI = api:get_ui_object("ragebot_targets")
        if rageTargetUI then
             rageTargetUI:SetValue(Target.Name)
             VehicleDestroyTargets[Target.Name] = true
        end
        if api and api.set_ragebot then
             api:set_ragebot(true)
        end
        
        if MyHum then MyHum.PlatformStand = false end
        return -- DONT KNOCK JUST DESTORY vehcile
    else
        -- Untarget from ragebot and proceed to fling
        if VehicleDestroyTargets[Target.Name] then
             local rageTargetUI = api:get_ui_object("ragebot_targets")
             if rageTargetUI then
                  rageTargetUI:SetValue("nil")
             end
             if api and api.set_ragebot then
                  api:set_ragebot(false)
             end
             VehicleDestroyTargets[Target.Name] = nil
        end
    end

    -- 1. GLUE (PhysicsRepRootPart)
    -- This keeps the physics engine happy that we are connected to them on the server
    if sethiddenproperty then
        pcall(function()
            sethiddenproperty(MyRoot, "PhysicsRepRootPart", TargetRoot)
        end)
    end
    
    -- 2. CALC POSITION (Ghost Fling / Desync)
    local basePos = TargetRoot.Position + GlueOffset
    local finalCFrame
    
    if Toggles['always_face_target'].Value then
         -- Dynamic Rotation logic
         local faceMode = Options['face_mode'].Value
         if faceMode == "Face Target" then
             finalCFrame = CFrame.lookAt(basePos, TargetRoot.Position)
         elseif faceMode == "Behind Target" then
             finalCFrame = CFrame.new(basePos) * (TargetRoot.CFrame - TargetRoot.Position)
         else
             finalCFrame = CFrame.new(basePos) * GlueAngle
         end
    else
         finalCFrame = CFrame.new(basePos) * GlueAngle
    end
    
    -- FORCE UPRIGHT LOGIC
    if Toggles['force_upright'] and Toggles['force_upright'].Value then
        local _, y, _ = finalCFrame:ToEulerAnglesYXZ()
        -- Reset Pitch(X) and Roll(Z) to 0, keep Yaw(Y)
        finalCFrame = CFrame.new(finalCFrame.Position) * CFrame.Angles(0, y, 0)
    end
    
    -- Apply Desync CFrame (Moves Server Hitbox)
    if api.set_desync_cframe then
        api:set_desync_cframe(finalCFrame)
    end
    
    -- 3. NAN FLING VELOCITY (Only if Flinging)
    -- Re-check toggle state inside loop for accuracy
    local flingActive = (Toggles['nan_fling_enabled'] and Toggles['nan_fling_enabled'].Value) or IsFlinging
    
    if flingActive then
        if MyHum then 
            MyHum.PlatformStand = true 
        end
        
        -- Apply Massive Velocity
        MyRoot.AssemblyLinearVelocity = NanVector
        MyRoot.AssemblyAngularVelocity = NanVector
        MyRoot.Velocity = NanVector
        MyRoot.RotVelocity = NanVector
        
        -- Attempt to move humanoid to trigger physics wake
        if MyHum then
            pcall(function() MyHum:Move(Vector3.new(0, 100, 0)) end) -- Move randomly/up
        end
    else
        -- Stable glue
        if MyHum then MyHum.PlatformStand = false end
    end
end)

-- Unload
api:on_event("unload", function()
    DisableGlue()
    api:notify("Nan Fling Unloaded", 2)
end)

api:notify("Nan Fling V2 Expanded Loaded", 5)
