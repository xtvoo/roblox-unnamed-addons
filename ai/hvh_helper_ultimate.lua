--[[
    🌸 ULTIMATE HvH HELPER - "SINGULARITY" EDITION 🌸
    Combined & Optimized by Antigravity
    
    Credits:
    - Original logic from: newtest(1).lua, tws.txt, 3dfinalv2.lua
    - API: xtvoo/unnamed_docs
    
    Features:
    - 🌐 Universal Strafe Engine (2D/3D Patterns)
    - ⚡ Kinetic Resolver (Velocity + Acceleration Prediction)
    - 🛡️ Void / Anti-Aim Logic (Y-Axis Manipulation)
    - 🌊 Chaos Engine (Pattern Randomization)
]]

-- [1. API SAFETY CHECK]
if not api or type(api.ragebot_strafe_override) ~= "function" then
    warn("[Singularity] API not found. Please inject 'unnamed'.")
    return
end

api:set_lua_name("Singularity HvH Helper")

-- [2. SERVICES]
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- [3. CONSTANTS & CONFIG]
local PATTERNS = {
    -- 2D Patterns
    "Orbit", "Square", "Triangle", "Pentagon", "Star", "Spiral", 
    "ZigZag", "Lemniscate", "Rose", "Butterfly", "Clover", "Cyclone",
    -- 3D Patterns
    "Sphere", "Atom", "DNA Helix", "Torus Knot", "Gyroscope"
}

local cfg = {
    -- Main
    enabled = false,
    
    -- Strafe
    pattern = "Orbit",
    radius_min = 12,
    radius_max = 24,
    speed = 10,
    speed_noise = 2,
    height_offset = 0,
    avoid_walls = true,
    
    -- Chaos
    chaos_enabled = false,
    chaos_amount = 0.3, 
    
    -- Resolver "Omni-Predict"
    resolver_enabled = false,
    pred_strength = 0.135,
    accel_comp = 0.5,
    
    anti_desync = true,
    
    resolver_enabled = false,
    pred_strength = 0.135,
    accel_comp = 0.5,
    anti_desync = true,
    
    -- V2: Cycle
    cycle_enabled = false,
    cycle_speed = 3,
    start_patterns = {},
    
    -- V2: Chaos
    stutter_chance = 0.05,
    stutter_duration = 0.2,
    
    -- V2: Wave
    wave_enabled = false,
    wave_height = 2,
    wave_speed = 2,
    
    -- V2: Ground
    ground_lock = true,
    ground_offset = 3,
}

local state = {
    angle = 0,
    ro = 0, -- Radial offset ticker
    t = os.clock(),
    
    -- Resolver State
    last_vel = Vector3.zero,
    calc_accel = Vector3.zero,
    
    -- V2 State
    cycle_idx = 1,
    cycle_next = 0,
    stutter_end = 0,
    
    seed = math.random(0, 10000)
}

-- [4. UI CONSTRUCTION]
local tab = api:GetTab("ragebot") or api:AddTab("ragebot")

-- helper to safely add a box
local function get_box()
    -- Try to find existing or create new
    -- Note: API docs say AddLeftTabbox returns the box object
    return tab:AddLeftTabbox("Singularity Helper") 
end

local box = get_box()
if not box then return end -- Safety

local mainTab = box:AddTab("Strafes")
local combatTab = box:AddTab("Combat")
local visualTab = box:AddTab("Extra")

-- // STRAFES TAB //
mainTab:AddToggle("sg_enable", {
    Text = "Enable Master Switch",
    Default = false,
    Tooltip = "Enables the Singularity engine",
    Callback = function(v) cfg.enabled = v end
})

mainTab:AddDropdown("sg_pattern", {
    Text = "Pattern Style",
    Values = PATTERNS,
    Default = "Orbit",
    Multi = false,
    Callback = function(v) cfg.pattern = v end
})

mainTab:AddSlider("sg_speed", {
    Text = "Strafe Speed",
    Min = 1, Max = 30,
    Default = 10,
    Rounding = 1,
    Callback = function(v) cfg.speed = v end
})

mainTab:AddLabel("Dimensions")
mainTab:AddSlider("sg_rmin", {
    Text = "Radius Min",
    Min = 2, Max = 100,
    Default = 12,
    Rounding = 0,
    Callback = function(v) cfg.radius_min = v end
})

mainTab:AddSlider("sg_rmax", {
    Text = "Radius Max",
    Min = 2, Max = 100,
    Default = 24,
    Rounding = 0,
    Callback = function(v) cfg.radius_max = v end
})

mainTab:AddSlider("sg_height", {
    Text = "Height Offset",
    Min = -10, Max = 10,
    Default = 0,
    Rounding = 1,
    Callback = function(v) cfg.height_offset = v end
})

mainTab:AddToggle("sg_avoid", {
    Text = "Avoid Walls",
    Default = true,
    Callback = function(v) cfg.avoid_walls = v end
})

mainTab:AddDivider()
mainTab:AddLabel("Chaos Engine")
mainTab:AddToggle("sg_chaos", {
    Text = "Enable Chaos",
    Default = false,
    Callback = function(v) cfg.chaos_enabled = v end
})
mainTab:AddSlider("sg_chaos_amt", {
    Text = "Chaos Amount",
    Min = 0.1, Max = 2.0,
    Default = 0.3,
    Rounding = 2,
    Callback = function(v) cfg.chaos_amount = v end
})

mainTab:AddToggle("sg_stutter", {
    Text = "Stutter/Freeze",
    Default = false,
    Tooltip = "Randomly stops movement to break tracking",
    Callback = function(v) cfg.stutter_chance = v and 0.05 or 0 end
})


mainTab:AddDivider()
mainTab:AddLabel("Pattern Cycling")
mainTab:AddToggle("sg_cycle_en", {
    Text = "Auto Cycle",
    Default = false,
    Callback = function(v) cfg.cycle_enabled = v end
})

mainTab:AddDropdown("sg_cycle_list", {
    Text = "Cycle Patterns",
    Values = PATTERNS,
    Default = {},
    Multi = true,
    Callback = function(v) cfg.start_patterns = v end
})

mainTab:AddSlider("sg_cycle_spd", {
    Text = "Cycle Interval",
    Min = 1, Max = 10,
    Default = 3,
    Rounding = 1,
    Callback = function(v) cfg.cycle_speed = v end
})

mainTab:AddDivider()
mainTab:AddLabel("Wave & Ground")
mainTab:AddToggle("sg_wave", {
    Text = "Wave Motion",
    Default = false,
    Callback = function(v) cfg.wave_enabled = v end
})

mainTab:AddSlider("sg_wave_h", {
    Text = "Wave Height",
    Min = 1, Max = 10,
    Default = 2,
    Rounding = 1,
    Callback = function(v) cfg.wave_height = v end
})

mainTab:AddToggle("sg_ground", {
    Text = "Ground Lock",
    Default = true, 
    Tooltip = "Raycasts to ground to keep strafe valid",
    Callback = function(v) cfg.ground_lock = v end
})

mainTab:AddSlider("sg_ground_off", {
    Text = "Ground Offset",
    Min = 0, Max = 10,
    Default = 3,
    Rounding = 1,
    Callback = function(v) cfg.ground_offset = v end
})



-- // COMBAT TAB //
combatTab:AddLabel("Kinetic Resolver")
combatTab:AddToggle("sg_res_en", {
    Text = "Enable Prediction",
    Default = false,
    Callback = function(v) cfg.resolver_enabled = v end
})

combatTab:AddSlider("sg_pred", {
    Text = "Reaction Time (s)",
    Min = 0.01, Max = 0.5,
    Default = 0.135,
    Rounding = 3,
    Callback = function(v) cfg.pred_strength = v end
})

combatTab:AddSlider("sg_accel", {
    Text = "Accel Compensation",
    Min = 0, Max = 2,
    Default = 0.5,
    Rounding = 2,
    Callback = function(v) cfg.accel_comp = v end
})





-- // EXTRA TAB //
visualTab:AddButton("Force Update Name", function()
    api:set_lua_name("Singularity v1-"..tostring(math.random(100,999)))
end)

visualTab:AddLabel("Credits: Antigravity")
visualTab:AddLabel("Built for 'unnamed'")


-- [5. MATH HELPER LIBRARY]

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function get_radius(tick_val)
    local diff = cfg.radius_max - cfg.radius_min
    if diff <= 0 then return cfg.radius_min end
    -- Breathe effect
    local s = (math.sin(tick_val * 0.5) + 1) * 0.5
    return cfg.radius_min + (diff * s)
end

-- Raycast to prevent clipping into walls
local function adjust_for_walls(origin, target)
    if not cfg.avoid_walls then return target end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    -- Filter local character
    local char = LocalPlayer and LocalPlayer.Character
    if char then params.FilterDescendantsInstances = {char} end
    
    local dir = target - origin
    local dist = dir.Magnitude
    if dist < 0.1 then return target end
    
    local result = Workspace:Raycast(origin, dir.Unit * dist, params)
    if result then
        -- Hit a wall, pull back slightly
        return result.Position - (dir.Unit * 1.5)
    end
    return target
end

-- The Core Pattern Generator
local function get_pattern_offset(pattern, angle, r)
    local c = math.cos(angle)
    local s = math.sin(angle)
    
    -- 2D Defaults
    local x, y, z = c * r, 0, s * r
    
    if pattern == "Orbit" then
        -- default
    elseif pattern == "Square" then
        -- Square math (approx)
        local a = angle % (math.pi/2)
        local sec = 1 / math.cos(a - math.pi/4)
        x = r * sec * c
        z = r * sec * s
    elseif pattern == "Triangle" then
        local a = angle % (2*math.pi/3)
        local sec = 1 / math.cos(a - math.pi/3)
        x = r * sec * c
        z = r * sec * s
    elseif pattern == "Star" then
        local k = 5
        local rho = r * (math.cos(k * angle) + 2) / 3
        x = rho * math.cos(angle)
        z = rho * math.sin(angle)
    elseif pattern == "Spiral" then
        local factor = (math.sin(angle/2)+1)/2
        local r_vary = r * (0.5 + 0.5*factor)
        x, z = r_vary * c, r_vary * s
    elseif pattern == "Lemniscate" then -- Infinity
        local denom = 1 + s*s
        x = r * c / denom
        z = r * c * s / denom
    elseif pattern == "Rose" then
        local k = 4
        local rho = r * math.cos(k * angle)
        x, z = rho * c, rho * s
    elseif pattern == "Butterfly" then
        local rho = r * math.exp(math.cos(angle)) - 2*math.cos(4*angle) - math.sin(angle/12)^5
        x, z = rho * c * 0.5, rho * s * 0.5 -- scale down a bit
    elseif pattern == "Cyclone" then
        local swirl = angle * 2
        local r2 = r + (math.sin(angle*5)*2)
        x, z = r2 * math.cos(swirl), r2 * math.sin(swirl)
        
    -- 3D Logic
    elseif pattern == "Sphere" then
        local phi = angle * 0.5
        x = r * math.sin(phi) * c
        y = r * math.cos(phi)
        z = r * math.sin(phi) * s
    elseif pattern == "Atom" then
        local phase = math.floor(angle / (math.pi*2)) % 3
        if phase == 0 then x,y,z = c*r, 0, s*r
        elseif phase == 1 then x,y,z = c*r, s*r, 0
        else x,y,z = 0, c*r, s*r end
    elseif pattern == "DNA Helix" then
        x = c*r
        z = s*r
        y = math.sin(angle*3) * (r*0.5)
    elseif pattern == "Torus Knot" then
        local p, q = 2, 3
        local r_tube = r * 0.3
        local R = r
        x = (R + r_tube * math.cos(q*angle)) * math.cos(p*angle)
        y = (R + r_tube * math.cos(q*angle)) * math.sin(p*angle)
        z = r_tube * math.sin(q*angle)
        -- Swap Y/Z for Roblox coordinates (Y is up)
        local temp = y; y = z; z = temp;
    elseif pattern == "Gyroscope" then
        local t = angle * 0.5
        x = r * math.cos(t)
        z = r * math.sin(t)
        y = r * math.cos(t*3) * 0.5
    end
    
    return Vector3.new(x, y, z)
end


-- [6. LOGIC LOOP]

api:add_connection(RunService.Heartbeat:Connect(function(dt)
    if not cfg.enabled then return end
    
    -- Speed Calculation
    local noise = 0
    if cfg.speed_noise > 0 then
        noise = (math.noise(os.clock(), state.seed) * cfg.speed_noise)
    end
    
    local final_speed = math.max(1, cfg.speed + noise)
    
    -- Increment Angle
    state.angle = state.angle + (final_speed * dt * 0.5) -- 0.5 to normalize rad/s feel
    state.ro = state.ro + (final_speed * dt * 0.1)
    
    -- Increment Angle
    state.angle = state.angle + (final_speed * dt * 0.5) -- 0.5 to normalize rad/s feel
    state.ro = state.ro + (final_speed * dt * 0.1)
    
    -- Physics Calculation (Acceleration)
    if cfg.resolver_enabled then
         -- Try to get target
        local t_cache = api:get_target_cache("ragebot")
        if t_cache and t_cache.part then
            local curr_vel = t_cache.part.AssemblyLinearVelocity or Vector3.zero
            state.calc_accel = (curr_vel - state.last_vel) / dt
            state.last_vel = curr_vel
            state.last_vel = Vector3.zero
            state.calc_accel = Vector3.zero
        end
    end
    
    -- V2: Pattern Cycling
    if cfg.cycle_enabled and os.clock() > state.cycle_next then
         -- Get list of selected patterns from dropdown
         local cycleList = {}
         for k, v in pairs(cfg.start_patterns) do
             if v then table.insert(cycleList, k) end
         end
         
         if #cycleList > 0 then
             state.cycle_idx = (state.cycle_idx % #cycleList) + 1
             local nextPat = cycleList[state.cycle_idx]
             if nextPat then
                 cfg.pattern = nextPat
                 -- Update UI if possible (optional, might require finding the dropdown object)
             end
         end
         state.cycle_next = os.clock() + cfg.cycle_speed
    end
end))


-- [7. OVERRIDE CALLBACK (THE MAGIC)]
-- This function is called by the cheat for every frame of ragebot movement
api:ragebot_strafe_override(function(current_pos, unsafe, target_part)
    if not cfg.enabled then return end
    if not target_part then return end -- sanity check
    
    -- V2: Stutter/Freeze
    if cfg.stutter_chance > 0 then
        if os.clock() < state.stutter_end then
             -- We are frozen
             return CFrame.lookAt(current_pos, target_part.Position), target_part.Position
        elseif math.random() < (cfg.stutter_chance / 60) then -- Per-frame chance
             -- Start freeze
             state.stutter_end = os.clock() + cfg.stutter_duration
             return CFrame.lookAt(current_pos, target_part.Position), target_part.Position
        end
    end
    
    local origin = target_part.Position
    local final_pos = origin
    
    -- A) RESOLVER: Predict where the target is GOING to be
    if cfg.resolver_enabled then
        local ping = 0.05 -- assume low ping or get from Stats
        if game.Stats.Network.ServerStatsItem["Data Ping"] then
            ping = game.Stats.Network.ServerStatsItem["Data Ping"].Value / 1000
        end
        
        -- Simple Linear Prediction (V1)
        local t = cfg.pred_strength + ping
        local v = target_part.AssemblyLinearVelocity or Vector3.zero
        -- Kinematics: P = P0 + Vt + 0.5at^2
        local pred = (v * t) + (state.calc_accel * 0.5 * t * t * cfg.accel_comp)
        
        origin = origin + pred
    end
    
    -- B) PATTERN: Calculate offset from (predicted) origin
    local r = get_radius(state.ro)
    local offset = get_pattern_offset(cfg.pattern, state.angle, r)
    
    -- C) CHAOS: Randomize path
    if cfg.chaos_enabled then
        local amt = cfg.chaos_amount
        local cx = (math.random() - 0.5) * amt * 5
        local cy = (math.random() - 0.5) * amt * 5
        local cz = (math.random() - 0.5) * amt * 5
        offset = offset + Vector3.new(cx, cy, cz)
    end
    
    -- D) WALL CHECK & HEIGHT
    -- Calculate Base Height component separately if needed
    local y_offset = cfg.height_offset
    
    -- V2: Wave Motion (Calculate Y contribution)
    if cfg.wave_enabled then
        local wave = math.sin(os.clock() * cfg.wave_speed) * cfg.wave_height
        y_offset = y_offset + wave
    end
    
    -- Apply Flat Offset First (X/Z)
    final_pos = origin + Vector3.new(offset.X, 0, offset.Z)
    
    -- V2: Ground Lock vs Air
    if cfg.ground_lock then
        -- Raycast from high up downwards at the strafe target X/Z
        local rayOrigin = final_pos + Vector3.new(0, 15, 0)
        local rayDir = Vector3.new(0, -100, 0)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        if LocalPlayer.Character then params.FilterDescendantsInstances = {LocalPlayer.Character} end
        
        local result = Workspace:Raycast(rayOrigin, rayDir, params)
        if result then
            -- Found Ground: Snap Y to Ground + Config Offset + Wave/Height
            final_pos = Vector3.new(final_pos.X, result.Position.Y + cfg.ground_offset + y_offset, final_pos.Z)
        else
            -- No Ground: Fallback to Origin Y + Offset
            final_pos = final_pos + Vector3.new(0, origin.Y + y_offset - final_pos.Y, 0) 
        end
    else
        -- Air Mode: Just add Y offset to Origin Y
        final_pos = final_pos + Vector3.new(0, y_offset + offset.Y, 0)
    end
    
    final_pos = adjust_for_walls(origin, final_pos)

    
    -- Return CFrame (Position + LookAt) AND the Focus Point (for camera/aim)
    return CFrame.lookAt(final_pos, target_part.Position), target_part.Position
end)

-- [8. PERSISTENCE]
local DATA_FILE = "resolver_data.json"

local function SaveData()
    if not writefile then return end
    local json = game:GetService("HttpService"):JSONEncode(state.res_data)
    writefile(DATA_FILE, json)
    api:notify("AI Data Saved", 2)
end

local function LoadData()
    if not readfile or not isfile then return end
    if isfile(DATA_FILE) then
        local content = readfile(DATA_FILE)
        local success, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
        if success and decoded then
            -- Merge into current state
            for k, v in pairs(decoded) do
                if state.res_data[k] then
                    state.res_data[k] = v
                end
            end
            api:notify("AI Data Loaded", 3)
            -- Update UI immediately if possible
            if UpdateAIStats then UpdateAIStats() end
        end
    end
end

-- Auto-Save Loop
spawn(function()
    while true do
        wait(30)
        SaveData()
    end
end)

-- Load on Startup
LoadData()

api:notify("Singularity Loaded", 5)
