--[[
    Custom Ragebot Override v2
    - Strafes: Only override XZ movement patterns
    - Void: Only override Y when target grounded (built-in not needed)
    - Chaos: XZ distortion only
    - Force Unsafe: Force ragebot to ignore unsafe checks
    - Stutter/Freeze: Movement disruption techniques
    - Auto Resolver: Adaptive prediction and anti-anti-aim
    
    Each system is independent and only affects its own domain.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════════
-- VALIDATION
-- ══════════════════════════════════════════════════════════════════
if not api or type(api.ragebot_strafe_override) ~= "function" then
    warn("[Override] API not available")
    return
end

api:set_lua_name("Ragebot Override v2")

-- ══════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ══════════════════════════════════════════════════════════════════
local STRAFE_PATTERNS = {
    "Orbit", "Square", "Triangle", "Pentagon", "Hexagon", "Star",
    "Spiral", "ZigZag", "Lemniscate", "Rose", "Butterfly", "Clover",
    "Cyclone", "PingPong", "Fidget", "Wave", "Cardioid", "Superellipse",
    "Diamond", "Heart", "Infinity", "Random"
}

local VOID_MODES = {
    "Bait", "Spam", "Dynamic", "Jitter", "Adaptive"
}

local STUTTER_MODES = {
    "Freeze", "Micro", "Teleport", "Shake", "Reverse", "Skip"
}

local RESOLVER_MODES = {
    "Off", "Basic", "Adaptive", "Aggressive", "Predictive"
}

-- ══════════════════════════════════════════════════════════════════
-- UI SETUP
-- ══════════════════════════════════════════════════════════════════
local tab = api:GetTab("ragebot") or api:AddTab("ragebot")
if not tab then
    warn("[Override] Failed to create tab")
    return
end

local tabbox = tab:AddLeftTabbox("Override")
if not tabbox then
    warn("[Override] Failed to create tabbox")
    return
end

local strafeTab = tabbox:AddTab("Strafes")
local voidTab = tabbox:AddTab("Void")
local chaosTab = tabbox:AddTab("Chaos")
local resolverTab = tabbox:AddTab("Resolver")
local extraTab = tabbox:AddTab("Extra")

-- ══════════════════════════════════════════════════════════════════
-- STRAFE UI
-- ══════════════════════════════════════════════════════════════════
local strafe_enable = strafeTab:AddToggle("co_strafe_enable", {
    Text = "Enable Strafes",
    Default = false,
    Tooltip = "Override XZ movement patterns around target",
})

local strafe_pattern = strafeTab:AddDropdown("co_strafe_pattern", {
    Text = "Pattern",
    Values = STRAFE_PATTERNS,
    Default = "Orbit",
    Multi = false,
})

strafeTab:AddDivider()

local strafe_radius_min = strafeTab:AddSlider("co_strafe_rmin", {
    Text = "Radius Min",
    Min = 2, Max = 100,
    Default = 10,
    Rounding = 1,
    Compact = true,
})

local strafe_radius_max = strafeTab:AddSlider("co_strafe_rmax", {
    Text = "Radius Max",
    Min = 2, Max = 150,
    Default = 25,
    Rounding = 1,
    Compact = true,
})

local strafe_speed = strafeTab:AddSlider("co_strafe_speed", {
    Text = "Speed",
    Min = 0.5, Max = 25,
    Default = 5,
    Rounding = 1,
    Compact = true,
})

strafeTab:AddDivider()

local strafe_ground_lock = strafeTab:AddToggle("co_strafe_ground", {
    Text = "Ground Lock",
    Default = false,
    Tooltip = "Lock strafe height to ground level",
})

local strafe_ground_height = strafeTab:AddSlider("co_strafe_ground_h", {
    Text = "Ground Height",
    Min = 0, Max = 15,
    Default = 3,
    Rounding = 1,
    Compact = true,
})

local strafe_avoid_walls = strafeTab:AddToggle("co_strafe_avoid", {
    Text = "Avoid Obstacles",
    Default = true,
})

strafeTab:AddDivider()

local strafe_auto_cycle = strafeTab:AddToggle("co_strafe_cycle", {
    Text = "Auto Cycle Patterns",
    Default = false,
})

local strafe_cycle_list = strafeTab:AddDropdown("co_strafe_cycle_list", {
    Text = "Cycle Patterns",
    Values = STRAFE_PATTERNS,
    Default = "",
    Multi = true,
})

local strafe_cycle_time = strafeTab:AddSlider("co_strafe_cycle_time", {
    Text = "Cycle Interval",
    Min = 0.5, Max = 10,
    Default = 2,
    Rounding = 2,
    Compact = true,
    Suffix = "s",
})

-- ══════════════════════════════════════════════════════════════════
-- VOID UI
-- ══════════════════════════════════════════════════════════════════
local void_enable = voidTab:AddToggle("co_void_enable", {
    Text = "Enable Void Override",
    Default = false,
    Tooltip = "Controls Y position when target is grounded",
})

local void_mode = voidTab:AddDropdown("co_void_mode", {
    Text = "Void Mode",
    Values = VOID_MODES,
    Default = "Bait",
    Multi = false,
})

voidTab:AddDivider()

local void_depth = voidTab:AddSlider("co_void_depth", {
    Text = "Void Depth",
    Min = 50, Max = 600,
    Default = 200,
    Rounding = 0,
    Compact = true,
})

local void_bait_height = voidTab:AddSlider("co_void_bait", {
    Text = "Bait Height",
    Min = 1, Max = 50,
    Default = 8,
    Rounding = 1,
    Compact = true,
})

voidTab:AddDivider()

local void_in_time = voidTab:AddSlider("co_void_in", {
    Text = "Time In Void",
    Min = 0.02, Max = 1,
    Default = 0.12,
    Rounding = 3,
    Compact = true,
    Suffix = "s",
})

local void_out_time = voidTab:AddSlider("co_void_out", {
    Text = "Time Out Void",
    Min = 0.02, Max = 1,
    Default = 0.18,
    Rounding = 3,
    Compact = true,
    Suffix = "s",
})

voidTab:AddDivider()

local void_y_jitter = voidTab:AddSlider("co_void_jitter", {
    Text = "Y Jitter",
    Min = 0, Max = 25,
    Default = 3,
    Rounding = 1,
    Compact = true,
})

local void_randomize = voidTab:AddToggle("co_void_random", {
    Text = "Randomize Timings",
    Default = true,
})

voidTab:AddDivider()

local void_grounded_only = voidTab:AddToggle("co_void_grounded", {
    Text = "Only When Target Grounded",
    Default = true,
    Tooltip = "Activate only when target is on ground",
})

local void_ground_threshold = voidTab:AddSlider("co_void_threshold", {
    Text = "Ground Threshold",
    Min = 5, Max = 100,
    Default = 40,
    Rounding = 0,
    Compact = true,
})

local void_max_distance = voidTab:AddSlider("co_void_max_dist", {
    Text = "Max Distance",
    Min = 50, Max = 500,
    Default = 250,
    Rounding = 0,
    Compact = true,
})

-- ══════════════════════════════════════════════════════════════════
-- CHAOS UI
-- ══════════════════════════════════════════════════════════════════
local chaos_enable = chaosTab:AddToggle("co_chaos_enable", {
    Text = "Enable Chaos",
    Default = false,
    Tooltip = "XZ randomization for strafes",
})

chaosTab:AddDivider()

local chaos_amount = chaosTab:AddSlider("co_chaos_amount", {
    Text = "Chaos Intensity",
    Min = 0, Max = 1,
    Default = 0.35,
    Rounding = 2,
    Compact = true,
})

local chaos_phase = chaosTab:AddSlider("co_chaos_phase", {
    Text = "Phase Offset",
    Min = 0, Max = 1,
    Default = 0.4,
    Rounding = 2,
    Compact = true,
})

chaosTab:AddDivider()

local chaos_jitter = chaosTab:AddSlider("co_chaos_jitter", {
    Text = "XZ Jitter",
    Min = 0, Max = 15,
    Default = 1.5,
    Rounding = 1,
    Compact = true,
})

local chaos_jitter_y = chaosTab:AddSlider("co_chaos_jitter_y", {
    Text = "Y Jitter (Non-Void)",
    Min = 0, Max = 10,
    Default = 0.5,
    Rounding = 1,
    Compact = true,
})

chaosTab:AddDivider()

local chaos_burst = chaosTab:AddToggle("co_chaos_burst", {
    Text = "Enable Burst",
    Default = false,
})

local chaos_burst_chance = chaosTab:AddSlider("co_chaos_burst_pct", {
    Text = "Burst Chance %",
    Min = 0, Max = 100,
    Default = 8,
    Rounding = 0,
    Compact = true,
})

local chaos_burst_dist = chaosTab:AddSlider("co_chaos_burst_dist", {
    Text = "Burst Distance",
    Min = 1, Max = 50,
    Default = 10,
    Rounding = 1,
    Compact = true,
})

chaosTab:AddDivider()

local chaos_wave = chaosTab:AddToggle("co_chaos_wave", {
    Text = "Wave Distortion",
    Default = false,
})

local chaos_wave_amp = chaosTab:AddSlider("co_chaos_wave_amp", {
    Text = "Wave Amplitude",
    Min = 0, Max = 25,
    Default = 4,
    Rounding = 1,
    Compact = true,
})

local chaos_wave_freq = chaosTab:AddSlider("co_chaos_wave_freq", {
    Text = "Wave Frequency",
    Min = 0.5, Max = 15,
    Default = 3,
    Rounding = 1,
    Compact = true,
})

-- ══════════════════════════════════════════════════════════════════
-- RESOLVER UI
-- ══════════════════════════════════════════════════════════════════
local resolver_enable = resolverTab:AddToggle("co_resolver_enable", {
    Text = "Enable Auto Resolver",
    Default = false,
    Tooltip = "Adaptive prediction and anti-desync",
})

local resolver_mode = resolverTab:AddDropdown("co_resolver_mode", {
    Text = "Resolver Mode",
    Values = RESOLVER_MODES,
    Default = "Adaptive",
    Multi = false,
})

resolverTab:AddDivider()

local resolver_prediction = resolverTab:AddSlider("co_resolver_pred", {
    Text = "Prediction Strength",
    Min = 0, Max = 2,
    Default = 0.8,
    Rounding = 2,
    Compact = true,
})

local resolver_history = resolverTab:AddSlider("co_resolver_history", {
    Text = "History Samples",
    Min = 3, Max = 30,
    Default = 12,
    Rounding = 0,
    Compact = true,
})

local resolver_refresh = resolverTab:AddSlider("co_resolver_refresh", {
    Text = "Refresh Rate",
    Min = 0.02, Max = 0.5,
    Default = 0.08,
    Rounding = 3,
    Compact = true,
    Suffix = "s",
})

resolverTab:AddDivider()

local resolver_velocity = resolverTab:AddToggle("co_resolver_vel", {
    Text = "Velocity Compensation",
    Default = true,
})

local resolver_acceleration = resolverTab:AddToggle("co_resolver_accel", {
    Text = "Acceleration Tracking",
    Default = true,
})

local resolver_desync = resolverTab:AddToggle("co_resolver_desync", {
    Text = "Anti-Desync",
    Default = true,
    Tooltip = "Detect and counter target desync",
})

resolverTab:AddDivider()

local resolver_desync_threshold = resolverTab:AddSlider("co_resolver_desync_th", {
    Text = "Desync Threshold",
    Min = 5, Max = 100,
    Default = 25,
    Rounding = 0,
    Compact = true,
})

local resolver_smooth = resolverTab:AddSlider("co_resolver_smooth", {
    Text = "Smoothing",
    Min = 0, Max = 1,
    Default = 0.3,
    Rounding = 2,
    Compact = true,
})

local resolver_overshoot = resolverTab:AddSlider("co_resolver_overshoot", {
    Text = "Overshoot Correction",
    Min = 0, Max = 1,
    Default = 0.15,
    Rounding = 2,
    Compact = true,
})

resolverTab:AddDivider()

local resolver_reset_on_miss = resolverTab:AddToggle("co_resolver_reset", {
    Text = "Reset On Miss",
    Default = true,
})

local resolver_adaptive_mult = resolverTab:AddToggle("co_resolver_adapt", {
    Text = "Adaptive Multiplier",
    Default = true,
})

-- ══════════════════════════════════════════════════════════════════
-- EXTRA UI (Force Unsafe, Stutter, Freeze)
-- ══════════════════════════════════════════════════════════════════
local force_unsafe = extraTab:AddToggle("co_force_unsafe", {
    Text = "Force Unsafe",
    Default = false,
    Tooltip = "Ignore unsafe checks (risky)",
})

extraTab:AddDivider()

local stutter_enable = extraTab:AddToggle("co_stutter_enable", {
    Text = "Enable Stutter",
    Default = false,
})

local stutter_mode = extraTab:AddDropdown("co_stutter_mode", {
    Text = "Stutter Mode",
    Values = STUTTER_MODES,
    Default = "Micro",
    Multi = false,
})

local stutter_intensity = extraTab:AddSlider("co_stutter_intensity", {
    Text = "Intensity",
    Min = 0.1, Max = 1,
    Default = 0.5,
    Rounding = 2,
    Compact = true,
})

local stutter_frequency = extraTab:AddSlider("co_stutter_freq", {
    Text = "Frequency",
    Min = 0.01, Max = 0.5,
    Default = 0.08,
    Rounding = 3,
    Compact = true,
    Suffix = "s",
})

local stutter_duration = extraTab:AddSlider("co_stutter_dur", {
    Text = "Duration",
    Min = 0.01, Max = 0.3,
    Default = 0.04,
    Rounding = 3,
    Compact = true,
    Suffix = "s",
})

extraTab:AddDivider()

local freeze_enable = extraTab:AddToggle("co_freeze_enable", {
    Text = "Enable Freeze",
    Default = false,
})

local freeze_interval = extraTab:AddSlider("co_freeze_interval", {
    Text = "Freeze Interval",
    Min = 0.2, Max = 3,
    Default = 0.8,
    Rounding = 2,
    Compact = true,
    Suffix = "s",
})

local freeze_duration = extraTab:AddSlider("co_freeze_dur", {
    Text = "Freeze Duration",
    Min = 0.02, Max = 0.5,
    Default = 0.12,
    Rounding = 3,
    Compact = true,
    Suffix = "s",
})

local freeze_random = extraTab:AddToggle("co_freeze_random", {
    Text = "Randomize Freeze",
    Default = true,
})

extraTab:AddDivider()

local debug_mode = extraTab:AddToggle("co_debug", {
    Text = "Debug Mode",
    Default = false,
})

-- ══════════════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════════════
local state = {
    t = os.clock(),
    
    -- Strafe
    strafe_angle = 0,
    strafe_radius_offset = 0,
    cycle_next = os.clock(),
    cycle_idx = 1,
    poly_idx = 1,
    poly_next = 0,
    
    -- Void
    void_timer = 0,
    void_in = false,
    void_last_switch = 0,
    
    -- Stutter/Freeze
    stutter_next = 0,
    stutter_active = false,
    stutter_end = 0,
    stutter_last_pos = nil,
    freeze_next = 0,
    freeze_active = false,
    freeze_end = 0,
    freeze_pos = nil,
    
    -- Resolver
    resolver_history = {},
    resolver_last_update = 0,
    resolver_velocity = Vector3.zero,
    resolver_acceleration = Vector3.zero,
    resolver_predicted = Vector3.zero,
    resolver_confidence = 0,
    resolver_miss_count = 0,
    resolver_hit_count = 0,
    resolver_last_target = nil,
    resolver_desync_detected = false,
    resolver_desync_offset = Vector3.zero,
    resolver_multiplier = 1,
}

-- ══════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ══════════════════════════════════════════════════════════════════
local function V(obj, default)
    if not obj then return default end
    local ok, val = pcall(function() return obj.Value end)
    return ok and val ~= nil and val or default
end

local function unit2()
    local a = math.random() * math.pi * 2
    return math.cos(a), math.sin(a)
end

local function lerp(a, b, t)
    return a + (b - a) * math.clamp(t, 0, 1)
end

local function lerpV3(a, b, t)
    return a:Lerp(b, math.clamp(t, 0, 1))
end

local function face(origin, pos)
    local f = origin - pos
    local m = f.Magnitude
    if m < 1e-4 then return CFrame.new(pos) end
    f = f / m
    local up = Vector3.yAxis
    local right = f:Cross(up)
    if right.Magnitude < 1e-4 then
        right = Vector3.xAxis
    else
        right = right.Unit
    end
    up = right:Cross(f).Unit
    return CFrame.fromMatrix(pos, right, up)
end

local function groundYAt(pos, ignore)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local ignoreList = {}
    local char = LocalPlayer and LocalPlayer.Character
    if char then table.insert(ignoreList, char) end
    
    if ignore then
        if typeof(ignore) == "Instance" then
            table.insert(ignoreList, ignore)
        elseif type(ignore) == "table" then
            for _, inst in ipairs(ignore) do
                if typeof(inst) == "Instance" then
                    table.insert(ignoreList, inst)
                end
            end
        end
    end
    
    params.FilterDescendantsInstances = ignoreList
    local result = Workspace:Raycast(pos + Vector3.new(0, 200, 0), Vector3.new(0, -1200, 0), params)
    return result and result.Position.Y or nil
end

local function isTargetGrounded(part, threshold)
    if not part then return false end
    local pos = part.Position
    local gy = groundYAt(pos, part.Parent)
    if not gy then return true end
    return math.abs(pos.Y - gy) < threshold
end

local function adjustForObstacles(origin, target, ignoreInst)
    local dir = target - origin
    local dist = dir.Magnitude
    if dist < 1 then return target end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    
    local ignoreList = {}
    local char = LocalPlayer and LocalPlayer.Character
    if char then table.insert(ignoreList, char) end
    
    if ignoreInst then
        if typeof(ignoreInst) == "Instance" then
            table.insert(ignoreList, ignoreInst)
        elseif type(ignoreInst) == "table" then
            for _, v in ipairs(ignoreInst) do
                if typeof(v) == "Instance" then
                    table.insert(ignoreList, v)
                end
            end
        end
    end
    
    params.FilterDescendantsInstances = ignoreList
    local result = Workspace:Raycast(origin, dir.Unit * dist, params)
    
    if result and result.Distance < dist then
        return origin + dir.Unit * math.max(result.Distance - 2, 1.5)
    end
    
    return target
end

local function getCycleList()
    local val = strafe_cycle_list and strafe_cycle_list.Value
    if not val then return STRAFE_PATTERNS end
    
    local out = {}
    if type(val) == "table" then
        local isMap = false
        for k, _ in pairs(val) do
            if type(k) == "string" then isMap = true break end
        end
        
        if isMap then
            for _, name in ipairs(STRAFE_PATTERNS) do
                if val[name] then
                    table.insert(out, name)
                end
            end
        else
            for _, name in ipairs(val) do
                table.insert(out, tostring(name))
            end
        end
    end
    
    return #out > 0 and out or STRAFE_PATTERNS
end

local function debugLog(...)
    if V(debug_mode, false) then
        print("[Override]", ...)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- RESOLVER SYSTEM
-- ══════════════════════════════════════════════════════════════════
local function updateResolverHistory(pos, now)
    local maxSamples = V(resolver_history, 12)
    
    table.insert(state.resolver_history, {
        pos = pos,
        time = now,
    })
    
    while #state.resolver_history > maxSamples do
        table.remove(state.resolver_history, 1)
    end
end

local function calculateVelocity()
    local history = state.resolver_history
    if #history < 2 then return Vector3.zero end
    
    local newest = history[#history]
    local oldest = history[1]
    local dt = newest.time - oldest.time
    
    if dt < 0.001 then return Vector3.zero end
    
    return (newest.pos - oldest.pos) / dt
end

local function calculateAcceleration()
    local history = state.resolver_history
    if #history < 3 then return Vector3.zero end
    
    local mid = math.floor(#history / 2)
    local oldest = history[1]
    local middle = history[mid]
    local newest = history[#history]
    
    local dt1 = middle.time - oldest.time
    local dt2 = newest.time - middle.time
    
    if dt1 < 0.001 or dt2 < 0.001 then return Vector3.zero end
    
    local v1 = (middle.pos - oldest.pos) / dt1
    local v2 = (newest.pos - middle.pos) / dt2
    
    local totalDt = newest.time - oldest.time
    if totalDt < 0.001 then return Vector3.zero end
    
    return (v2 - v1) / totalDt
end

local function detectDesync(part, currentPos)
    if not part then return false, Vector3.zero end
    
    local threshold = V(resolver_desync_threshold, 25)
    local history = state.resolver_history
    
    if #history < 3 then return false, Vector3.zero end
    
    local predicted = history[#history].pos + state.resolver_velocity * 0.05
    local actual = currentPos
    local diff = (actual - predicted).Magnitude
    
    if diff > threshold then
        local offset = actual - predicted
        return true, offset
    end
    
    return false, Vector3.zero
end

local function resolvePosition(part, basePos, now, dt)
    if not V(resolver_enable, false) then return basePos end
    if not part then return basePos end
    
    local mode = V(resolver_mode, "Adaptive")
    if mode == "Off" then return basePos end
    
    local refreshRate = V(resolver_refresh, 0.08)
    local predStrength = V(resolver_prediction, 0.8)
    local smooth = V(resolver_smooth, 0.3)
    local overshoot = V(resolver_overshoot, 0.15)
    
    -- Check if target changed
    local targetPlayer = part.Parent and Players:GetPlayerFromCharacter(part.Parent)
    if targetPlayer ~= state.resolver_last_target then
        state.resolver_history = {}
        state.resolver_velocity = Vector3.zero
        state.resolver_acceleration = Vector3.zero
        state.resolver_confidence = 0
        state.resolver_miss_count = 0
        state.resolver_hit_count = 0
        state.resolver_desync_detected = false
        state.resolver_desync_offset = Vector3.zero
        state.resolver_multiplier = 1
        state.resolver_last_target = targetPlayer
    end
    
    -- Update at refresh rate
    if now - state.resolver_last_update >= refreshRate then
        updateResolverHistory(basePos, now)
        state.resolver_last_update = now
        
        if V(resolver_velocity, true) then
            state.resolver_velocity = calculateVelocity()
        end
        
        if V(resolver_acceleration, true) then
            state.resolver_acceleration = calculateAcceleration()
        end
        
        if V(resolver_desync, true) then
            local detected, offset = detectDesync(part, basePos)
            state.resolver_desync_detected = detected
            if detected then
                state.resolver_desync_offset = lerpV3(state.resolver_desync_offset, offset, 0.6)
            else
                state.resolver_desync_offset = lerpV3(state.resolver_desync_offset, Vector3.zero, 0.3)
            end
        end
        
        -- Update confidence
        local velMag = state.resolver_velocity.Magnitude
        if velMag > 5 then
            state.resolver_confidence = math.min(state.resolver_confidence + 0.1, 1)
        else
            state.resolver_confidence = math.max(state.resolver_confidence - 0.05, 0)
        end
    end
    
    -- Calculate prediction based on mode
    local prediction = Vector3.zero
    local mult = state.resolver_multiplier
    
    if mode == "Basic" then
        prediction = state.resolver_velocity * predStrength * 0.05 * mult
        
    elseif mode == "Adaptive" then
        local velPred = state.resolver_velocity * predStrength * 0.05
        local accelPred = state.resolver_acceleration * predStrength * 0.002
        prediction = (velPred + accelPred) * state.resolver_confidence * mult
        
    elseif mode == "Aggressive" then
        local velPred = state.resolver_velocity * predStrength * 0.08
        local accelPred = state.resolver_acceleration * predStrength * 0.004
        prediction = (velPred + accelPred) * mult * 1.3
        
    elseif mode == "Predictive" then
        local velPred = state.resolver_velocity * predStrength * 0.06
        local accelPred = state.resolver_acceleration * predStrength * 0.003
        local jerkEstimate = state.resolver_acceleration * 0.02
        prediction = (velPred + accelPred + jerkEstimate) * state.resolver_confidence * mult
    end
    
    -- Apply desync compensation
    if state.resolver_desync_detected then
        prediction = prediction - state.resolver_desync_offset * 0.5
    end
    
    -- Apply overshoot correction
    if prediction.Magnitude > 1 then
        prediction = prediction * (1 - overshoot * (1 - state.resolver_confidence))
    end
    
    -- Smooth the prediction
    state.resolver_predicted = lerpV3(state.resolver_predicted, prediction, 1 - smooth)
    
    local resolved = basePos + state.resolver_predicted
    
    debugLog("Resolver:", mode, "vel:", math.floor(state.resolver_velocity.Magnitude), 
             "conf:", string.format("%.2f", state.resolver_confidence),
             "desync:", state.resolver_desync_detected)
    
    return resolved
end

-- Adaptive multiplier based on hits/misses
api:on_event("localplayer_hit_player", function(player, part, damage, weapon, origin, position)
    if not V(resolver_adaptive_mult, true) then return end
    
    state.resolver_hit_count = state.resolver_hit_count + 1
    state.resolver_miss_count = math.max(0, state.resolver_miss_count - 1)
    
    local ratio = state.resolver_hit_count / math.max(1, state.resolver_hit_count + state.resolver_miss_count)
    state.resolver_multiplier = lerp(state.resolver_multiplier, 0.8 + ratio * 0.4, 0.2)
    
    debugLog("Hit! Multiplier:", string.format("%.2f", state.resolver_multiplier))
end)

-- Track misses (approximate by checking if we shot but didn't hit)
local lastShotTime = 0
api:add_connection(RunService.Heartbeat:Connect(function()
    if not V(resolver_adaptive_mult, true) then return end
    if not V(resolver_enable, false) then return end
    
    local cache = api:get_tool_cache()
    if not cache or not cache.gun then return end
    
    local now = os.clock()
    
    -- Detect shot (ammo decreased)
    if cache.ammo and cache._lastAmmo and cache.ammo < cache._lastAmmo then
        lastShotTime = now
    end
    cache._lastAmmo = cache.ammo
    
    -- If shot happened but no hit event in 0.2s, count as miss
    if lastShotTime > 0 and now - lastShotTime > 0.2 then
        if V(resolver_reset_on_miss, true) then
            state.resolver_miss_count = state.resolver_miss_count + 1
            
            local ratio = state.resolver_hit_count / math.max(1, state.resolver_hit_count + state.resolver_miss_count)
            state.resolver_multiplier = lerp(state.resolver_multiplier, 0.6 + ratio * 0.5, 0.15)
        end
        lastShotTime = 0
    end
end))

-- ══════════════════════════════════════════════════════════════════
-- STUTTER/FREEZE SYSTEM
-- ══════════════════════════════════════════════════════════════════
local function processStutter(pos, now)
    if not V(stutter_enable, false) then 
        state.stutter_active = false
        return pos 
    end
    
    local mode = V(stutter_mode, "Micro")
    local intensity = V(stutter_intensity, 0.5)
    local frequency = V(stutter_frequency, 0.08)
    local duration = V(stutter_duration, 0.04)
    
    -- Check if stutter should activate
    if not state.stutter_active and now >= state.stutter_next then
        state.stutter_active = true
        state.stutter_end = now + duration
        state.stutter_last_pos = pos
        state.stutter_next = now + frequency + (math.random() - 0.5) * frequency * 0.3
    end
    
    -- Check if stutter should end
    if state.stutter_active and now >= state.stutter_end then
        state.stutter_active = false
    end
    
    if not state.stutter_active then
        state.stutter_last_pos = pos
        return pos
    end
    
    local offset = Vector3.zero
    
    if mode == "Freeze" then
        return state.stutter_last_pos or pos
        
    elseif mode == "Micro" then
        local rx, rz = unit2()
        offset = Vector3.new(rx * intensity * 3, 0, rz * intensity * 3)
        
    elseif mode == "Teleport" then
        local rx, rz = unit2()
        offset = Vector3.new(rx * intensity * 15, 0, rz * intensity * 15)
        
    elseif mode == "Shake" then
        local phase = (now * 50) % (math.pi * 2)
        offset = Vector3.new(
            math.sin(phase * 3) * intensity * 5,
            math.sin(phase * 4) * intensity * 2,
            math.cos(phase * 3) * intensity * 5
        )
        
    elseif mode == "Reverse" then
        if state.stutter_last_pos then
            local dir = pos - state.stutter_last_pos
            return pos - dir * intensity * 2
        end
        
    elseif mode == "Skip" then
        local skip = math.floor(now / duration) % 2 == 0
        if skip then
            return state.stutter_last_pos or pos
        end
    end
    
    return pos + offset
end

local function processFreeze(pos, now)
    if not V(freeze_enable, false) then
        state.freeze_active = false
        return pos
    end
    
    local interval = V(freeze_interval, 0.8)
    local duration = V(freeze_duration, 0.12)
    local randomize = V(freeze_random, true)
    
    local actualInterval = interval
    if randomize then
        actualInterval = interval * (0.7 + math.random() * 0.6)
    end
    
    -- Check if freeze should activate
    if not state.freeze_active and now >= state.freeze_next then
        state.freeze_active = true
        state.freeze_end = now + duration
        state.freeze_pos = pos
        state.freeze_next = now + actualInterval
    end
    
    -- Check if freeze should end
    if state.freeze_active and now >= state.freeze_end then
        state.freeze_active = false
        state.freeze_pos = nil
    end
    
    if state.freeze_active and state.freeze_pos then
        return state.freeze_pos
    end
    
    return pos
end

-- ══════════════════════════════════════════════════════════════════
-- STRAFE PATTERNS
-- ══════════════════════════════════════════════════════════════════
local PATTERN_FUNCTIONS = {}

local function pattern_orbit(r, ang)
    return Vector3.new(r * math.cos(ang), 0, r * math.sin(ang))
end
PATTERN_FUNCTIONS.Orbit = pattern_orbit

local function pattern_square(r, ang)
    local p = (ang % (2 * math.pi)) / (2 * math.pi)
    local s, h = r * 2, r
    local x, z
    if p < 0.25 then
        x, z = -h + s * (p / 0.25), -h
    elseif p < 0.5 then
        x, z = h, -h + s * ((p - 0.25) / 0.25)
    elseif p < 0.75 then
        x, z = h - s * ((p - 0.5) / 0.25), h
    else
        x, z = -h, h - s * ((p - 0.75) / 0.25)
    end
    return Vector3.new(x, 0, z)
end
PATTERN_FUNCTIONS.Square = pattern_square

local function pattern_polygon(r, ang, sides)
    local p = (ang % (2 * math.pi)) / (2 * math.pi)
    local seg = math.floor(p * sides)
    local t = (p * sides) % 1
    local a1 = seg * (2 * math.pi / sides) - math.pi / 2
    local a2 = (seg + 1) * (2 * math.pi / sides) - math.pi / 2
    local p1 = Vector3.new(r * math.cos(a1), 0, r * math.sin(a1))
    local p2 = Vector3.new(r * math.cos(a2), 0, r * math.sin(a2))
    return p1:Lerp(p2, t)
end

PATTERN_FUNCTIONS.Triangle = function(r, ang) return pattern_polygon(r, ang, 3) end
PATTERN_FUNCTIONS.Pentagon = function(r, ang) return pattern_polygon(r, ang, 5) end
PATTERN_FUNCTIONS.Hexagon = function(r, ang) return pattern_polygon(r, ang, 6) end

local function pattern_star(r, ang)
    local N = 5
    local p = (ang % (2 * math.pi)) / (2 * math.pi)
    local idx = math.floor(p * N)
    local t = (p * N) % 1
    local i1 = idx
    local i2 = (idx + 2) % N
    local a1 = i1 * (2 * math.pi / N) - math.pi / 2
    local a2 = i2 * (2 * math.pi / N) - math.pi / 2
    local p1 = Vector3.new(r * math.cos(a1), 0, r * math.sin(a1))
    local p2 = Vector3.new(r * math.cos(a2), 0, r * math.sin(a2))
    return p1:Lerp(p2, t)
end
PATTERN_FUNCTIONS.Star = pattern_star

local function pattern_spiral(r, ang)
    local turns = 3
    local progress = (ang / (2 * math.pi * turns)) % 1
    local rr = r * (0.2 + 0.8 * progress)
    return Vector3.new(rr * math.cos(ang), 0, rr * math.sin(ang))
end
PATTERN_FUNCTIONS.Spiral = pattern_spiral

local function pattern_zigzag(r, ang)
    local seg = math.floor((ang % (2 * math.pi)) / (math.pi / 6))
    local dir = (seg % 2 == 0) and 1 or -1
    local amp = math.max(2, 0.4 * r)
    local rr = r + dir * amp * math.sin(5 * ang)
    return Vector3.new(rr * math.cos(ang), 0, rr * math.sin(ang))
end
PATTERN_FUNCTIONS.ZigZag = pattern_zigzag

local function pattern_lemniscate(r, ang)
    local a = r * 0.75
    local c = math.cos(2 * ang)
    local rho = (c > 0) and math.sqrt(2) * a * math.sqrt(c) or r * 0.1
    return Vector3.new(rho * math.cos(ang), 0, rho * math.sin(ang))
end
PATTERN_FUNCTIONS.Lemniscate = pattern_lemniscate

local function pattern_rose(r, ang)
    local petals = 5
    local rho = r * math.max(0.1, math.abs(math.cos(petals * ang)))
    return Vector3.new(rho * math.cos(ang), 0, rho * math.sin(ang))
end
PATTERN_FUNCTIONS.Rose = pattern_rose

local function pattern_butterfly(r, t)
    local rr = math.exp(math.sin(t)) - 2 * math.cos(4 * t) + (math.sin((2 * t - math.pi) / 24)) ^ 5
    local s = r * 0.35
    return Vector3.new(s * rr * math.cos(t), 0, s * rr * math.sin(t))
end
PATTERN_FUNCTIONS.Butterfly = pattern_butterfly

local function pattern_clover(r, ang)
    local leaves = 4
    local rho = r * (0.4 + 0.6 * math.abs(math.cos(leaves * ang / 2)))
    return Vector3.new(rho * math.cos(ang), 0, rho * math.sin(ang))
end
PATTERN_FUNCTIONS.Clover = pattern_clover

local function pattern_cyclone(r, ang)
    local swirl = ang * 1.4
    local radial = r * (0.35 + 0.65 * (0.5 + 0.5 * math.sin(ang * 1.5)))
    local wobble = 0.12 * r * math.sin(ang * 4)
    return Vector3.new((radial + wobble) * math.cos(swirl), 0, (radial - wobble) * math.sin(swirl))
end
PATTERN_FUNCTIONS.Cyclone = pattern_cyclone

local function pattern_pingpong(r, ang)
    local rayAng = ang * 0.5
    local saw = (ang / math.pi) % 2
    local u = (saw < 1) and saw or (2 - saw)
    local rho = r * 0.25 + r * 0.75 * u
    return Vector3.new(rho * math.cos(rayAng), 0, rho * math.sin(rayAng))
end
PATTERN_FUNCTIONS.PingPong = pattern_pingpong

local function pattern_fidget(r, t)
    local lobes = 3
    local step = (2 * math.pi) / lobes
    local rot = t * 0.9
    local idx = math.floor((t * 0.8) % lobes)
    local lobeAngle = rot + idx * step
    local ring = r * 0.85 + r * 0.15 * math.sin(t * 5)
    local hubOrbit = r * 0.2 * math.sin(t * 2)
    return Vector3.new(
        ring * math.cos(lobeAngle) + hubOrbit * math.cos(rot * 2),
        0,
        ring * math.sin(lobeAngle) + hubOrbit * math.sin(rot * 2)
    )
end
PATTERN_FUNCTIONS.Fidget = pattern_fidget

local function pattern_wave(r, ang)
    local waveAmp = r * 0.25
    local rr = r + waveAmp * math.sin(5 * ang)
    return Vector3.new(rr * math.cos(ang), 0, rr * math.sin(ang))
end
PATTERN_FUNCTIONS.Wave = pattern_wave

local function pattern_cardioid(r, ang)
    local rho = r * 0.5 * (1 - math.cos(ang))
    rho = math.max(rho, r * 0.1)
    return Vector3.new(rho * math.cos(ang), 0, rho * math.sin(ang))
end
PATTERN_FUNCTIONS.Cardioid = pattern_cardioid

local function pattern_superellipse(r, ang)
    local n = 3.5
    local cx = ((math.cos(ang) >= 0) and 1 or -1) * math.abs(math.cos(ang)) ^ (2 / n)
    local cz = ((math.sin(ang) >= 0) and 1 or -1) * math.abs(math.sin(ang)) ^ (2 / n)
    return Vector3.new(r * cx, 0, r * cz)
end
PATTERN_FUNCTIONS.Superellipse = pattern_superellipse

local function pattern_diamond(r, ang)
    local p = (ang % (2 * math.pi)) / (2 * math.pi)
    local coords = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
    local seg = math.floor(p * 4) + 1
    seg = math.clamp(seg, 1, 4)
    local t = (p * 4) % 1
    local c1 = coords[seg]
    local c2 = coords[(seg % 4) + 1]
    local x = lerp(c1[1], c2[1], t) * r
    local z = lerp(c1[2], c2[2], t) * r
    return Vector3.new(x, 0, z)
end
PATTERN_FUNCTIONS.Diamond = pattern_diamond

local function pattern_heart(r, t)
    local scale = r * 0.055
    local x = 16 * math.sin(t) ^ 3
    local z = 13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t)
    return Vector3.new(x * scale, 0, -z * scale)
end
PATTERN_FUNCTIONS.Heart = pattern_heart

local function pattern_infinity(r, ang)
    local scale = r * 0.65
    local denom = 1 + math.sin(ang)^2
    if denom < 0.1 then denom = 0.1 end
    local x = scale * math.cos(ang) / denom
    local z = scale * math.sin(ang) * math.cos(ang) / denom
    return Vector3.new(x, 0, z)
end
PATTERN_FUNCTIONS.Infinity = pattern_infinity

local function pattern_random(r, ang, now)
    if now >= state.poly_next then
        state.poly_idx = math.random(1, #STRAFE_PATTERNS - 1)
        state.poly_next = now + math.random() * 0.4 + 0.15
    end
    
    local patternName = STRAFE_PATTERNS[state.poly_idx]
    local func = PATTERN_FUNCTIONS[patternName]
    if func and patternName ~= "Random" then
        return func(r, ang, now)
    end
    return pattern_orbit(r, ang)
end
PATTERN_FUNCTIONS.Random = pattern_random

-- ══════════════════════════════════════════════════════════════════
-- CHAOS SYSTEM
-- ══════════════════════════════════════════════════════════════════
local function applyChaos(offset, r, t)
    if not V(chaos_enable, false) then return offset end
    
    local amount = V(chaos_amount, 0.35)
    if amount <= 0 then return offset end
    
    local dx, dz = offset.X, offset.Z
    local m = math.max(1e-6, math.sqrt(dx * dx + dz * dz))
    local tx, tz = dx / m, dz / m
    local nx, nz = -tz, tx
    
    local phase = V(chaos_phase, 0.4)
    
    local offN = amount * 0.35 * r * math.sin(6 * t + phase * math.pi)
    local offT = amount * 0.25 * r * math.sin(4 * t + phase * 2.5)
    local radMult = 1.0 + 0.25 * amount * math.sin(7 * t + phase * 1.5)
    
    local px = (dx * radMult) + nx * offN + tx * offT
    local pz = (dz * radMult) + nz * offN + tz * offT
    
    return Vector3.new(px, offset.Y, pz)
end

local function applyJitter(offset, voidActive)
    if not V(chaos_enable, false) then return offset end
    
    local jitterXZ = V(chaos_jitter, 1.5)
    local jitterY = V(chaos_jitter_y, 0.5)
    
    local jx, jz = 0, 0
    local jy = 0
    
    if jitterXZ > 0 then
        local ax, az = unit2()
        jx = ax * jitterXZ
        jz = az * jitterXZ
    end
    
    if not voidActive and jitterY > 0 then
        jy = (math.random() - 0.5) * 2 * jitterY
    end
    
    return offset + Vector3.new(jx, jy, jz)
end

local function applyBurst(offset)
    if not V(chaos_burst, false) then return offset end
    
    local chance = V(chaos_burst_chance, 8)
    if math.random(0, 1000) >= chance * 10 then return offset end
    
    local dist = V(chaos_burst_dist, 10)
    local bx, bz = unit2()
    
    return offset + Vector3.new(bx * dist, 0, bz * dist)
end

local function applyWave(offset, t, voidActive)
    if not V(chaos_wave, false) then return offset end
    if voidActive then return offset end
    
    local amp = V(chaos_wave_amp, 4)
    local freq = V(chaos_wave_freq, 3)
    
    local waveY = amp * math.sin(t * freq)
    return offset + Vector3.new(0, waveY, 0)
end

-- ══════════════════════════════════════════════════════════════════
-- VOID SYSTEM
-- ══════════════════════════════════════════════════════════════════
local function shouldActivateVoid(origin, part)
    if not V(void_enable, false) then return false end
    
    if V(void_grounded_only, true) then
        local threshold = V(void_ground_threshold, 40)
        if not isTargetGrounded(part, threshold) then
            return false
        end
    end
    
    local maxDist = V(void_max_distance, 250)
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - origin).Magnitude
            if dist > maxDist then
                return false
            end
        end
    end
    
    return true
end

local function calculateVoidY(origin, dt, now)
    local mode = V(void_mode, "Bait")
    local depth = V(void_depth, 200)
    local baitHeight = V(void_bait_height, 8)
    local inTime = V(void_in_time, 0.12)
    local outTime = V(void_out_time, 0.18)
    local yJitter = V(void_y_jitter, 3)
    local randomize = V(void_randomize, true)
    
    local actualInTime = inTime
    local actualOutTime = outTime
    if randomize then
        actualInTime = inTime * (0.7 + math.random() * 0.6)
        actualOutTime = outTime * (0.7 + math.random() * 0.6)
    end
    
    local yOffset = 0
    
    if mode == "Bait" then
        local cycleTime = actualInTime + actualOutTime
        state.void_timer = state.void_timer + dt
        local cyclePos = state.void_timer % cycleTime
        
        if cyclePos < actualInTime then
            yOffset = -depth
            state.void_in = true
        else
            yOffset = baitHeight
            state.void_in = false
        end
        
    elseif mode == "Spam" then
        local switchTime = (actualInTime + actualOutTime) / 2
        if now - state.void_last_switch >= switchTime then
            state.void_in = not state.void_in
            state.void_last_switch = now
        end
        yOffset = state.void_in and -depth or baitHeight
        
    elseif mode == "Dynamic" then
        state.void_timer = state.void_timer + dt
        local cycleTime = actualInTime + actualOutTime
        local progress = (state.void_timer % cycleTime) / cycleTime
        local sine = math.sin(progress * math.pi * 2)
        
        yOffset = baitHeight + (sine * 0.5 - 0.5) * (depth + baitHeight)
        state.void_in = yOffset < 0
        
    elseif mode == "Jitter" then
        if math.random() > 0.65 then
            yOffset = -depth + (math.random() - 0.5) * depth * 0.3
            state.void_in = true
        else
            yOffset = baitHeight + (math.random() - 0.5) * baitHeight * 0.5
            state.void_in = false
        end
        
    elseif mode == "Adaptive" then
        local cycleFactor = math.sin(now * 2.5)
        local randomFactor = math.random() - 0.5
        
        if cycleFactor + randomFactor > 0.3 then
            yOffset = baitHeight * (0.8 + math.random() * 0.4)
            state.void_in = false
        else
            yOffset = -depth * (0.6 + math.random() * 0.4)
            state.void_in = true
        end
    end
    
    if yJitter > 0 then
        yOffset = yOffset + (math.random() - 0.5) * 2 * yJitter
    end
    
    return yOffset
end

-- ══════════════════════════════════════════════════════════════════
-- MAIN STRAFE OVERRIDE
-- ══════════════════════════════════════════════════════════════════
api:ragebot_strafe_override(function(position, unsafe, part)
    local now = os.clock()
    local dt = math.clamp(now - state.t, 1/300, 0.15)
    state.t = now
    
    -- Force unsafe check
    local forceUnsafe = V(force_unsafe, false)
    local effectiveUnsafe = unsafe and not forceUnsafe
    
    -- Update strafe state
    local speed = V(strafe_speed, 5)
    state.strafe_angle = state.strafe_angle + speed * dt
    state.strafe_radius_offset = state.strafe_radius_offset + speed * 0.55 * dt
    
    local origin = part and part.Position or position
    local ignoreInst = part and part.Parent or nil
    
    -- Apply resolver to origin
    local resolvedOrigin = resolvePosition(part, origin, now, dt)
    
    -- Check conditions
    local strafeEnabled = V(strafe_enable, false) and not effectiveUnsafe
    local voidActive = shouldActivateVoid(origin, part) and not effectiveUnsafe
    
    -- ════════════════════════════════════════════════════════════
    -- STRAFE CALCULATION (XZ Only)
    -- ════════════════════════════════════════════════════════════
    local strafeOffset = Vector3.zero
    
    if strafeEnabled then
        -- Auto cycle patterns
        if V(strafe_auto_cycle, false) and now >= state.cycle_next then
            local list = getCycleList()
            if #list > 0 then
                state.cycle_idx = (state.cycle_idx % #list) + 1
                local nextPattern = list[state.cycle_idx]
                if nextPattern and strafe_pattern and strafe_pattern.SetValue then
                    strafe_pattern:SetValue(nextPattern)
                end
            end
            state.cycle_next = now + V(strafe_cycle_time, 2)
        end
        
        -- Calculate radius with oscillation
        local rmin = math.max(2, V(strafe_radius_min, 10))
        local rmax = math.max(rmin, V(strafe_radius_max, 25))
        local rmid = (rmin + rmax) / 2
        local ramp = (rmax - rmin) / 2
        local r = rmid + ramp * math.sin(state.strafe_radius_offset)
        
        -- Get pattern
        local patternName = V(strafe_pattern, "Orbit")
        local patternFunc = PATTERN_FUNCTIONS[patternName] or pattern_orbit
        
        -- Calculate base offset
        strafeOffset = patternFunc(r, state.strafe_angle, now)
        
        -- Apply chaos
        strafeOffset = applyChaos(strafeOffset, r, state.strafe_angle)
        strafeOffset = applyJitter(strafeOffset, voidActive)
        strafeOffset = applyBurst(strafeOffset)
        strafeOffset = applyWave(strafeOffset, state.strafe_angle, voidActive)
    end
    
    -- ════════════════════════════════════════════════════════════
    -- Y POSITION CALCULATION
    -- ════════════════════════════════════════════════════════════
    local finalY = resolvedOrigin.Y + strafeOffset.Y
    
    if voidActive then
        local voidY = calculateVoidY(origin, dt, now)
        finalY = origin.Y + voidY
        
    elseif strafeEnabled and V(strafe_ground_lock, false) then
        local targetPos = resolvedOrigin + Vector3.new(strafeOffset.X, 0, strafeOffset.Z)
        local gy = groundYAt(targetPos, ignoreInst)
        if gy then
            finalY = gy + V(strafe_ground_height, 3)
        end
    end
    
    -- ════════════════════════════════════════════════════════════
    -- FINAL POSITION
    -- ════════════════════════════════════════════════════════════
    if not strafeEnabled and not voidActive then
        return nil
    end
    
    local finalPos = Vector3.new(
        resolvedOrigin.X + strafeOffset.X,
        finalY,
        resolvedOrigin.Z + strafeOffset.Z
    )
    
    -- Apply stutter/freeze
    finalPos = processStutter(finalPos, now)
    finalPos = processFreeze(finalPos, now)
    
    -- Avoid obstacles
    if strafeEnabled and V(strafe_avoid_walls, true) then
        finalPos = adjustForObstacles(origin, finalPos, ignoreInst)
    end
    
    -- Create facing CFrame
    local shootPos = resolvedOrigin
    local result = face(shootPos, finalPos)
    
    return result, shootPos
end)

-- ══════════════════════════════════════════════════════════════════
-- UNLOAD
-- ══════════════════════════════════════════════════════════════════
api:on_event("unload", function()
    state = nil
    api:notify("Ragebot Override v2 unloaded", 3)
end)

api:notify("Ragebot Override v2 loaded!", 3)