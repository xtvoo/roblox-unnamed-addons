-- Set the lua name
api:set_lua_name("RocketTP Addon")

-- Services
local players_service = cloneref(game:GetService("Players"))
local local_player = players_service.LocalPlayer
local run_service = cloneref(game:GetService("RunService"))
local workspace = cloneref(game:GetService("Workspace"))
local replicated_storage = cloneref(game:GetService("ReplicatedStorage"))

-- Global toggles
getgenv().RocketTPEnabled = false
getgenv().PredictionEnabled = false
getgenv().HandleTPEnabled = false
getgenv().OrbitMode = false
getgenv().AutoBombMode = false
getgenv().AutoThrowEnabled = false
getgenv().ShieldModeEnabled = false
getgenv().RainbowGrenades = false

-- Orbit settings
local orbitAngle = 0
local grenadeIndex = 0
local patternTimer = 0
local grenadeTimers = {}
local grenadeOffsets = {}
local grenadeCounter = 0
local lastAutoThrow = 0
local rainbowHue = 0
local shieldGrenades = {}

-- Utility Functions
local function has_character(player)
    return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function teleport_rocket(object, target)
    if not has_character(target) then return end

    local is_grenade_launcher = object.Name == "GrenadeLauncherAmmo"
    local part = is_grenade_launcher and object:WaitForChild("Main") or object:WaitForChild("Launcher")

    part.CFrame = CFrame.new(1, 1, 1)

    if not is_grenade_launcher then
        if part:FindFirstChild("BodyVelocity") then
            part.BodyVelocity:Destroy()
        end
        if part:FindFirstChild("TouchInterest") then
            part.TouchInterest:Destroy()
        end
    end

    local connection = api:add_connection(run_service.Heartbeat:Connect(function()
        if has_character(target) then
            local target_position = target.Character.HumanoidRootPart.Position
            local target_velocity = target.Character.HumanoidRootPart.Velocity

            if PredictionEnabled then
                local predict_amount = math.clamp(target_velocity.Magnitude / 50, 0.18, 0.25) * 1.10
                target_position = target_position + (target_velocity * predict_amount)
            end

            -- ORBIT MODE
            if OrbitMode then
                local orbit_radius = Options.orbit_radius and Options.orbit_radius.Value or 10
                local orbit_speed = Options.orbit_speed and Options.orbit_speed.Value or 5
                
                orbitAngle = orbitAngle + (orbit_speed * 0.1)
                
                local offset_x = math.cos(math.rad(orbitAngle)) * orbit_radius
                local offset_z = math.sin(math.rad(orbitAngle)) * orbit_radius
                
                target_position = target_position + Vector3.new(offset_x, 0, offset_z)
            end

            part.CFrame = CFrame.new(target_position)
            part.Velocity = Vector3.new(0, 0.001, 0)
        end
    end))

    api:add_connection(object.Destroying:Connect(function()
        connection:Disconnect()
    end))
end

local function on_rocket_added(object)
    if RocketTPEnabled and (object.Name == "Model" or object.Name == "GrenadeLauncherAmmo") then
        local target = api:get_target("silent")
        if target and has_character(target) then
            teleport_rocket(object, target)
        end
    end
end

-- 666 MODE PATTERNS 😈💀
local function get_pattern_position(pattern, index, radius, target_pos)
    if pattern == "Circle" then
        local angle = (index * 45) % 360
        local x = math.cos(math.rad(angle)) * radius
        local z = math.sin(math.rad(angle)) * radius
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "Star" then
        local angle = (index * 72) % 360
        local r = (index % 2 == 0) and radius or radius * 0.5
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "Plus" then
        local positions = {
            Vector3.new(radius, 3, 0),
            Vector3.new(-radius, 3, 0),
            Vector3.new(0, 3, radius),
            Vector3.new(0, 3, -radius),
            Vector3.new(0, 3, 0)
        }
        return target_pos + (positions[(index % #positions) + 1] or Vector3.new(0, 3, 0))
        
    elseif pattern == "Diamond" then
        local positions = {
            Vector3.new(radius, 3, 0),
            Vector3.new(0, 3, radius),
            Vector3.new(-radius, 3, 0),
            Vector3.new(0, 3, -radius)
        }
        return target_pos + (positions[(index % #positions) + 1] or Vector3.new(0, 3, 0))
        
    elseif pattern == "Spiral" then
        local angle = index * 45
        local r = (index * 2) % radius
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "Triangle" then
        local positions = {
            Vector3.new(0, 3, radius),
            Vector3.new(radius * 0.866, 3, -radius * 0.5),
            Vector3.new(-radius * 0.866, 3, -radius * 0.5)
        }
        return target_pos + (positions[(index % #positions) + 1] or Vector3.new(0, 3, 0))
        
    elseif pattern == "Bullseye" then
        local ring = math.floor(index / 8)
        local angle = (index * 45) % 360
        local r = radius - (ring * 3)
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "Zigzag" then
        local x = (index % 2 == 0) and radius or -radius
        local z = (index * 3) % radius
        return target_pos + Vector3.new(x, 3, z)
    
    -- 666 MODE PATTERNS 😈💀🔥
    elseif pattern == "Pentagram" then
        local points = 5
        local angle = (index * (360 / points)) - 90
        local inner_radius = radius * 0.382
        local r = (index % 2 == 0) and radius or inner_radius
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "Hexagram" then
        local angle = (index * 60) % 360
        local r = (index % 2 == 0) and radius or radius * 0.577
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "Chaos" then
        math.randomseed(index)
        local angle = math.random(0, 360)
        local r = math.random(5, radius)
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, math.random(1, 5), z)
        
    elseif pattern == "Vortex" then
        local angle = (index * 66.6) % 360
        local r = radius - (index * 0.5)
        r = math.max(r, 2)
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "666" then
        local ring = math.floor(index / 6)
        local angle = (index % 6) * 60
        local r = radius - (ring * 4)
        r = math.max(r, 3)
        local x = math.cos(math.rad(angle)) * r
        local z = math.sin(math.rad(angle)) * r
        return target_pos + Vector3.new(x, 3, z)
        
    elseif pattern == "Inferno" then
        local angle = index * 66.6
        local height = (index * 0.5) % 10
        local x = math.cos(math.rad(angle)) * radius
        local z = math.sin(math.rad(angle)) * radius
        return target_pos + Vector3.new(x, height, z)
        
    elseif pattern == "Demon Circle" then
        local circle_num = index % 3
        local angle = (index * 40) % 360
        local offset = circle_num == 0 and Vector3.new(radius * 0.5, 3, 0) or 
                      circle_num == 1 and Vector3.new(-radius * 0.25, 3, radius * 0.433) or
                      Vector3.new(-radius * 0.25, 3, -radius * 0.433)
        local x = math.cos(math.rad(angle)) * (radius * 0.4)
        local z = math.sin(math.rad(angle)) * (radius * 0.4)
        return target_pos + offset + Vector3.new(x, 0, z)
        
    elseif pattern == "X Mark" then
        local positions = {
            Vector3.new(radius, 3, radius),
            Vector3.new(-radius, 3, -radius),
            Vector3.new(radius, 3, -radius),
            Vector3.new(-radius, 3, radius),
            Vector3.new(0, 3, 0)
        }
        return target_pos + (positions[(index % #positions) + 1] or Vector3.new(0, 3, 0))
        
    else
        return target_pos + Vector3.new(0, 3, 0)
    end
end

local function disable_grenade_explosion(handle)
    if handle:FindFirstChild("TouchInterest") then
        handle.TouchInterest:Destroy()
    end
    
    handle.CanCollide = false
    
    if handle:FindFirstChild("BodyVelocity") then
        handle.BodyVelocity:Destroy()
    end
    
    handle.Anchored = true
end

local function teleport_handle(target)
    if not has_character(target) then return end
    if not has_character(local_player) then return end

    local target_velocity = target.Character.HumanoidRootPart.Velocity
    local target_speed = target_velocity.Magnitude
    local predict_amount = math.clamp(target_speed / 50, 0.18, 0.47)
    local target_pos = target.Character.HumanoidRootPart.Position + (target_velocity * predict_amount)
    local player_pos = local_player.Character.HumanoidRootPart.Position

    local pattern = Options.grenade_pattern and Options.grenade_pattern.Value or "Normal"
    local radius = Options.pattern_radius and Options.pattern_radius.Value or 10
    local pattern_speed = Options.pattern_speed and Options.pattern_speed.Value or 5
    local grenade_height = Options.grenade_height and Options.grenade_height.Value or 3

    patternTimer = patternTimer + (pattern_speed * 0.1)
    if patternTimer >= 1 then
        grenadeIndex = grenadeIndex + 1
        patternTimer = 0
    end

    if RainbowGrenades then
        rainbowHue = (rainbowHue + 2) % 360
    end

    for _, handle in workspace.Ignored:GetChildren() do
        if handle:IsA("BasePart") and not handle.Anchored then
            if not grenadeTimers[handle] then
                grenadeTimers[handle] = tick()
                grenadeCounter = grenadeCounter + 1
                grenadeOffsets[handle] = (grenadeCounter * 60) % 360
            end
            
            local elapsed_time = tick() - grenadeTimers[handle]
            local orbit_time = Options.auto_bomb_time and Options.auto_bomb_time.Value or 2
            
            local final_pos
            
            -- SHIELD MODE 🛡️
            if ShieldModeEnabled then
                if not shieldGrenades[handle] then
                    shieldGrenades[handle] = true
                    disable_grenade_explosion(handle)
                end
                
                local shield_radius = Options.shield_radius and Options.shield_radius.Value or 6
                local shield_speed = Options.shield_speed and Options.shield_speed.Value or 15
                local shield_height = Options.shield_height and Options.shield_height.Value or 2
                
                orbitAngle = orbitAngle + (shield_speed * 0.1)
                local grenade_angle = orbitAngle + grenadeOffsets[handle]
                
                local offset_x = math.cos(math.rad(grenade_angle)) * shield_radius
                local offset_z = math.sin(math.rad(grenade_angle)) * shield_radius
                
                final_pos = player_pos + Vector3.new(offset_x, shield_height, offset_z)
                handle.BrickColor = BrickColor.new("Cyan")
                handle.CFrame = CFrame.new(final_pos)
                
            -- AUTO BOMB MODE 💣
            elseif AutoBombMode and elapsed_time >= orbit_time then
                if shieldGrenades[handle] then
                    handle.Anchored = false
                    handle.CanCollide = true
                    shieldGrenades[handle] = nil
                end
                
                final_pos = target_pos + Vector3.new(0, 1, 0)
                handle.Position = final_pos
                handle.BrickColor = BrickColor.new("Really red")
            elseif AutoBombMode then
                local auto_orbit_radius = Options.auto_bomb_radius and Options.auto_bomb_radius.Value or 8
                local auto_orbit_speed = Options.auto_bomb_speed and Options.auto_bomb_speed.Value or 10
                
                orbitAngle = orbitAngle + (auto_orbit_speed * 0.1)
                local grenade_angle = orbitAngle + grenadeOffsets[handle]
                
                local offset_x = math.cos(math.rad(grenade_angle)) * auto_orbit_radius
                local offset_z = math.sin(math.rad(grenade_angle)) * auto_orbit_radius
                
                final_pos = player_pos + Vector3.new(offset_x, grenade_height, offset_z)
                handle.Position = final_pos
                handle.BrickColor = BrickColor.new("Bright yellow")
            elseif pattern == "Normal" then
                if OrbitMode then
                    local orbit_radius = Options.orbit_radius and Options.orbit_radius.Value or 10
                    local orbit_speed = Options.orbit_speed and Options.orbit_speed.Value or 5
                    
                    orbitAngle = orbitAngle + (orbit_speed * 0.1)
                    
                    local offset_x = math.cos(math.rad(orbitAngle)) * orbit_radius
                    local offset_z = math.sin(math.rad(orbitAngle)) * orbit_radius
                    
                    final_pos = target_pos + Vector3.new(offset_x, grenade_height, offset_z)
                else
                    final_pos = target_pos + Vector3.new(0, 1, 0)
                end
                handle.Position = final_pos
                handle.BrickColor = BrickColor.new("Bright yellow")
            else
                local animated_index = grenadeIndex
                final_pos = get_pattern_position(pattern, animated_index, radius, target_pos)
                handle.Position = final_pos
                handle.BrickColor = BrickColor.new("Bright yellow")
            end
            
            if RainbowGrenades and not ShieldModeEnabled then
                handle.Color = Color3.fromHSV(rainbowHue / 360, 1, 1)
            end
        end
    end
    
    for handle, _ in pairs(grenadeTimers) do
        if not handle or not handle.Parent then
            grenadeTimers[handle] = nil
            grenadeOffsets[handle] = nil
            shieldGrenades[handle] = nil
        end
    end
end

local function update_handle_tp()
    if HandleTPEnabled then
        local target = api:get_target("silent")
        if target and has_character(target) then
            teleport_handle(target)
        end
    end
end

-- AUTO THROW GRENADES 🔄
local function auto_throw_grenades()
    if not AutoThrowEnabled then return end
    
    local current_time = tick()
    local throw_delay = Options.auto_throw_delay and Options.auto_throw_delay.Value or 1
    
    if current_time - lastAutoThrow >= throw_delay then
        lastAutoThrow = current_time
        
        task.spawn(function()
            for _, tool in ipairs(local_player.Backpack:GetChildren()) do
                if tool.Name == "[Grenade]" or tool.Name == "Grenade" then
                    tool.Parent = local_player.Character
                    task.wait(0.05)
                    tool:Activate()
                    task.wait(0.05)
                    tool:Activate()
                    return
                end
            end
        end)
    end
end

-- Buy Functions
local function buy_grenades()
    task.spawn(function()
        local amount = Options.grenade_amount and Options.grenade_amount.Value or 1
        
        api:notify("Buying " .. amount .. " grenade(s)...", 2)
        
        for i = 1, amount do
            repeat task.wait(0.1) until api:can_desync()
            
            pcall(function()
                api:buy_item("[Grenade] - $765", false, false)
            end)
            
            task.wait(0.2)
        end
        
        api:notify("Finished buying " .. amount .. " grenades!", 2)
    end)
end

local function buy_custom_item()
    task.spawn(function()
        local item = Options.custom_item_input and Options.custom_item_input.Value or "[Grenade]"
        local amount = Options.custom_item_amount and Options.custom_item_amount.Value or 1
        
        api:notify("Buying " .. amount .. "x " .. item .. "...", 2)
        
        for i = 1, amount do
            repeat task.wait(0.1) until api:can_desync()
            
            pcall(function()
                api:buy_item(item, false, false)
            end)
            
            task.wait(0.2)
        end
        
        api:notify("Finished buying " .. item .. "!", 2)
    end)
end

-- AUTO BUY + THROW SPAM 🔥
local function grenade_spam()
    task.spawn(function()
        local spam_amount = Options.spam_amount and Options.spam_amount.Value or 5
        
        api:notify("🔥 GRENADE SPAM ACTIVATED! 🔥", 2)
        
        for i = 1, spam_amount do
            repeat task.wait(0.1) until api:can_desync()
            
            pcall(function()
                api:buy_item("[Grenade]", false, false)
            end)
            
            task.wait(0.15)
            
            for _, tool in ipairs(local_player.Backpack:GetChildren()) do
                if tool.Name == "[Grenade]" or tool.Name == "Grenade" then
                    tool.Parent = local_player.Character
                    task.wait(0.05)
                    tool:Activate()
                    task.wait(0.05)
                    tool:Activate()
                    break
                end
            end
            
            task.wait(0.1)
        end
        
        api:notify("💣 SPAM COMPLETE! 💣", 3)
    end)
end

local function throw_all_grenades()
    task.spawn(function()
        local grenade_count = 0
        
        for _, tool in ipairs(local_player.Backpack:GetChildren()) do
            if tool.Name == "[Grenade]" or tool.Name == "Grenade" or (tool:FindFirstChild("Handle") and tool.ToolTip == "KABOOM") then
                grenade_count = grenade_count + 1
            end
        end
        
        if grenade_count == 0 then
            api:notify("No grenades in backpack!", 2)
            return
        end
        
        api:notify("Throwing " .. grenade_count .. " grenades!", 2)
        
        for _, tool in ipairs(local_player.Backpack:GetChildren()) do
            if tool.Name == "[Grenade]" or tool.Name == "Grenade" or (tool:FindFirstChild("Handle") and tool.ToolTip == "KABOOM") then
                tool.Parent = local_player.Character
                task.wait(0.05)
                tool:Activate()
                task.wait(0.05)
                tool:Activate()
                task.wait(0.02)
            end
        end
        
        api:notify("💣 ALL GRENADES DEPLOYED! 💣", 3)
    end)
end

-- UI Setup
local tab = api:AddTab("extra")
local rocketGroup = tab:AddLeftGroupbox("rocket tp")
local advancedGroup = tab:AddRightGroupbox("advanced")

rocketGroup:AddToggle("rocket_tp_toggle", {
    Text = "Rocket Teleport",
    Default = false,
    Callback = function(value)
        RocketTPEnabled = value
        api:notify("Rocket Teleport " .. (value and "Enabled" or "Disabled"), 2)
    end
})

rocketGroup:AddToggle("prediction_toggle", {
    Text = "Prediction",
    Default = false,
    Callback = function(value)
        PredictionEnabled = value
        api:notify("Prediction " .. (value and "Enabled" or "Disabled"), 2)
    end
})

rocketGroup:AddToggle("handle_tp_toggle", {
    Text = "Grenade TP",
    Default = false,
    Callback = function(value)
        HandleTPEnabled = value
        grenadeIndex = 0
        patternTimer = 0
        grenadeTimers = {}
        grenadeOffsets = {}
        grenadeCounter = 0
        shieldGrenades = {}
        api:notify("Grenade TP " .. (value and "Enabled" or "Disabled"), 2)
    end
})

rocketGroup:AddLabel("--- Auto Bomb Mode 💣 ---")

rocketGroup:AddToggle("auto_bomb_toggle", {
    Text = "Auto Bomb Mode",
    Default = false,
    Callback = function(value)
        AutoBombMode = value
        ShieldModeEnabled = false
        grenadeTimers = {}
        grenadeOffsets = {}
        grenadeCounter = 0
        shieldGrenades = {}
        api:notify("💣 Auto Bomb " .. (value and "Enabled" or "Disabled"), 2)
    end
})

rocketGroup:AddSlider("auto_bomb_time", {
    Text = "Orbit Time",
    Default = 2,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Suffix = "s"
})

rocketGroup:AddSlider("auto_bomb_radius", {
    Text = "Orbit Radius",
    Default = 8,
    Min = 3,
    Max = 15,
    Rounding = 1,
    Compact = false,
    Suffix = " studs"
})

rocketGroup:AddSlider("auto_bomb_speed", {
    Text = "Orbit Speed",
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 1,
    Compact = false
})

rocketGroup:AddLabel("--- Shield Mode 🛡️ ---")

rocketGroup:AddToggle("shield_mode_toggle", {
    Text = "Shield Mode",
    Default = false,
    Callback = function(value)
        ShieldModeEnabled = value
        AutoBombMode = false
        grenadeTimers = {}
        grenadeOffsets = {}
        grenadeCounter = 0
        shieldGrenades = {}
        api:notify("🛡️ Shield Mode " .. (value and "Enabled" or "Disabled"), 2)
    end,
    Tooltip = "Grenades orbit you without exploding"
})

rocketGroup:AddSlider("shield_radius", {
    Text = "Shield Radius",
    Default = 6,
    Min = 3,
    Max = 12,
    Rounding = 1,
    Compact = false,
    Suffix = " studs"
})

rocketGroup:AddSlider("shield_speed", {
    Text = "Shield Speed",
    Default = 15,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Compact = false
})

rocketGroup:AddSlider("shield_height", {
    Text = "Shield Height",
    Default = 2,
    Min = 0,
    Max = 6,
    Rounding = 1,
    Compact = false,
    Suffix = " studs"
})

advancedGroup:AddLabel("--- Pattern Mode ---")

advancedGroup:AddDropdown("grenade_pattern", {
    Values = {
        "Normal", "Circle", "Star", "Plus", "Diamond", "Spiral", "Triangle", "Bullseye", "Zigzag",
        "Pentagram", "Hexagram", "Chaos", "Vortex", "666", "Inferno", "Demon Circle", "X Mark"
    },
    Default = 1,
    Multi = false,
    Text = "Grenade Pattern",
    Callback = function(value)
        grenadeIndex = 0
        patternTimer = 0
        api:notify("Pattern: " .. value, 2)
    end
})

advancedGroup:AddSlider("pattern_radius", {
    Text = "Pattern Size",
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 1,
    Compact = false,
    Suffix = " studs"
})

advancedGroup:AddSlider("pattern_speed", {
    Text = "Pattern Speed",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Compact = false
})

advancedGroup:AddSlider("grenade_height", {
    Text = "Grenade Height",
    Default = 3,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Suffix = " studs"
})

advancedGroup:AddLabel("--- Visual Effects ---")

advancedGroup:AddToggle("rainbow_grenades_toggle", {
    Text = "🌈 Rainbow Grenades",
    Default = false,
    Callback = function(value)
        RainbowGrenades = value
        api:notify("🌈 Rainbow " .. (value and "Enabled" or "Disabled"), 2)
    end
})

advancedGroup:AddLabel("--- Orbit Mode ---")

advancedGroup:AddToggle("orbit_mode_toggle", {
    Text = "Orbit Mode",
    Default = false,
    Callback = function(value)
        OrbitMode = value
        if value then
            orbitAngle = 0
        end
        api:notify("Orbit Mode " .. (value and "Enabled" or "Disabled"), 2)
    end
})

advancedGroup:AddSlider("orbit_radius", {
    Text = "Orbit Radius",
    Default = 10,
    Min = 3,
    Max = 30,
    Rounding = 1,
    Compact = false,
    Suffix = " studs"
})

advancedGroup:AddSlider("orbit_speed", {
    Text = "Orbit Speed",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Compact = false
})

advancedGroup:AddLabel("--- Auto Throw 🔄 ---")

advancedGroup:AddToggle("auto_throw_toggle", {
    Text = "Auto Throw",
    Default = false,
    Callback = function(value)
        AutoThrowEnabled = value
        lastAutoThrow = tick()
        api:notify("🔄 Auto Throw " .. (value and "Enabled" or "Disabled"), 2)
    end
})

advancedGroup:AddSlider("auto_throw_delay", {
    Text = "Throw Delay",
    Default = 1,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Suffix = "s"
})

advancedGroup:AddLabel("--- Shop ---")

advancedGroup:AddSlider("grenade_amount", {
    Text = "Grenade Amount",
    Default = 1,
    Min = 1,
    Max = 11,
    Rounding = 0,
    Compact = false
})

advancedGroup:AddButton({
    Text = "Buy Grenades",
    Func = buy_grenades
})

advancedGroup:AddInput("custom_item_input", {
    Default = "[Grenade]",
    Numeric = false,
    Finished = true,
    Text = "Item Name",
    Placeholder = "[Grenade]"
})

advancedGroup:AddSlider("custom_item_amount", {
    Text = "Custom Item Amount",
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Compact = false
})

advancedGroup:AddButton({
    Text = "Buy Custom Item",
    Func = buy_custom_item
})

advancedGroup:AddLabel("--- Actions ---")

advancedGroup:AddButton({
    Text = "💣 THROW ALL GRENADES 💣",
    Func = throw_all_grenades
})

advancedGroup:AddSlider("spam_amount", {
    Text = "Spam Amount",
    Default = 5,
    Min = 1,
    Max = 15,
    Rounding = 0,
    Compact = false
})

advancedGroup:AddButton({
    Text = "🔥 GRENADE SPAM 🔥",
    Func = grenade_spam
})

api:add_connection(run_service.Heartbeat:Connect(function()
    auto_throw_grenades()
end))

api:add_connection(workspace.Ignored.ChildAdded:Connect(on_rocket_added))
api:add_connection(run_service.Heartbeat:Connect(update_handle_tp))

api:on_event("unload", function()
    api:notify("RocketTP Addon Unloaded", 2)
end)

api:notify("😈 ULTIMATE GRENADE MODE LOADED 😈", 3)
