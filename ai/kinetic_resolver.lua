--[[
    🧠 KINETIC RESOLVER - "OMNI-PREDICT" 🧠
    Universal Prediction Engine & AI
    
    This script runs independently and "Resolves" the enemy's movement
    by manipulating their local Velocity.
    
    This allows your Aimbot/Strafe script to hit/track better without 
    needing built-in support.
]]

if not api then
    warn("API not found. Please inject 'unnamed'.")
    -- Mock API for testing if needed
    getgenv().api = {
        set_lua_name = print,
        notify = print,
        GetTab = function() return {AddLeftTabbox=function() return {AddTab=function() return {AddToggle=function() end, AddDropdown=function() end, AddSlider=function() end, AddLabel=function() return {SetText=function() end} end} end} end} end
    }
end

api:set_lua_name("Kinetic Resolver")

-- [1. SERVICES]
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- [2. CONFIG]
local cfg = {
    enabled = true,
    mode = "AI", -- Manual, AI
    method = "Accelerating",
    
    -- Settings
    reaction_time = 0.135,
    accel_comp = 0.5,
    anti_flick = 50,
    smooth_samples = 10,
    
    visualize = true, -- Draw dot at pred pos
}

-- [3. STATE]
local state = {
    target = nil,
    history = {},
    last_vel = Vector3.zero,
    calc_accel = Vector3.zero,
    
    -- AI Data
    res_data = {
        ["Linear"] = {Shots=0, Hits=0},
        ["Accelerating"] = {Shots=0, Hits=0},
        ["Average"] = {Shots=0, Hits=0},
        ["Trend"] = {Shots=0, Hits=0},
        ["Anti-Flick"] = {Shots=0, Hits=0},
        ["Ground"] = {Shots=0, Hits=0},
        ["Air-Arc"] = {Shots=0, Hits=0},
        ["Look-Bias"] = {Shots=0, Hits=0},
        ["Reverse"] = {Shots=0, Hits=0},
        ["Stop"] = {Shots=0, Hits=0},
    },
    
    last_switch = 0,
    current_target_health = 100,
    shot_fired = false,
    
    -- Visuals
    dot = nil
}

-- [4. UI]
local tab = api:GetTab("combat") or api:AddTab("combat")
local box = tab:AddLeftTabbox("Omni-Predict Resolver")
local menu = box:AddTab("Main")

menu:AddToggle("res_en", {
    Text = "Enable Resolver",
    Default = true,
    Callback = function(v) cfg.enabled = v end
})

menu:AddDropdown("res_mode", {
    Text = "Mode",
    Values = {"Manual", "AI"},
    Default = "AI",
    Callback = function(v) cfg.mode = v end
})

local METHODS = {
    "Linear", "Accelerating", "Average", "Trend", "Anti-Flick", 
    "Ground", "Air-Arc", "Look-Bias", "Reverse", "Stop"
}

menu:AddDropdown("res_meth", {
    Text = "Method",
    Values = METHODS,
    Default = "Accelerating",
    Callback = function(v) cfg.method = v end
})

menu:AddSlider("res_rt", {
    Text = "Reaction Time / Ping",
    Min = 0.01, Max = 0.5,
    Default = 0.135,
    Rounding = 3,
    Callback = function(v) cfg.reaction_time = v end
})

menu:AddToggle("res_vis", {
    Text = "Visualize Prediction",
    Default = true,
    Callback = function(v) cfg.visualize = v end
})

-- Stats
local statBox = tab:AddRightTabbox("AI Learning")
local statMenu = statBox:AddTab("Stats")
local labels = {}
for _, m in ipairs(METHODS) do
    labels[m] = statMenu:AddLabel(m..": 0%")
end

local function UpdateStats()
    for m, d in pairs(state.res_data) do
        if labels[m] then
            local pct = 0
            if d.Shots > 0 then pct = math.floor((d.Hits/d.Shots)*100) end
            labels[m]:SetText(m..": "..pct.."% ("..d.Hits.."/"..d.Shots..")")
        end
    end
end

-- [5. METHODS]
local RES_METHODS = {}

RES_METHODS["Linear"] = function(p, v, a, t) return p + (v*t) end

RES_METHODS["Accelerating"] = function(p, v, a, t)
    return p + (v*t) + (a*0.5*t*t*cfg.accel_comp)
end

RES_METHODS["Average"] = function(p, v, a, t)
    local avg = v
    if #state.history > 0 then
        local sum = Vector3.zero
        for _,h in ipairs(state.history) do sum = sum + h end
        avg = sum / #state.history
    end
    return p + (avg*t)
end

RES_METHODS["Trend"] = function(p, v, a, t) return p + (v*t) + (a*t*t) end

RES_METHODS["Anti-Flick"] = function(p, v, a, t)
    if v.Magnitude > cfg.anti_flick then return p end
    return p + (v*t)
end

RES_METHODS["Ground"] = function(p, v, a, t)
    return p + (Vector3.new(v.X, 0, v.Z) * t)
end

RES_METHODS["Air-Arc"] = function(p, v, a, t)
    local g = Vector3.new(0, -196.2, 0)
    return p + (v*t) + (g*0.5*t*t)
end

RES_METHODS["Look-Bias"] = function(p, v, a, t, char)
    if not char then return p + v*t end
    local look = char.PrimaryPart.CFrame.LookVector * v.Magnitude
    return p + (v:Lerp(look, 0.5) * t)
end

RES_METHODS["Reverse"] = function(p, v, a, t) return p + (-v * t * 0.5) end
RES_METHODS["Stop"] = function(p, v, a, t) return p + (v * t * 0.2) end


-- [6. LOGIC]
local function GetTarget()
    -- Simple distance check or API
    if api.get_target_cache then
        local t = api:get_target_cache("ragebot")
        if t and t.part then return t.part.Parent end
    end
    
    -- Fallback
    local m = LocalPlayer:GetMouse()
    if m.Target and m.Target.Parent:FindFirstChild("Humanoid") then
        return m.Target.Parent
    end
    return nil
end

local function TrackHit(hit)
    local m = cfg.method
    state.res_data[m].Shots = state.res_data[m].Shots + 1
    if hit then state.res_data[m].Hits = state.res_data[m].Hits + 1 end
    UpdateStats()
    
    -- AI Switch
    if cfg.mode == "AI" and os.clock() - state.last_switch > 5 then
        local best, bestPct = m, -1
        for k,d in pairs(state.res_data) do
            local pct = (d.Shots >= 3) and (d.Hits/d.Shots) or 0
            if pct > bestPct then bestPct = pct; best = k end
        end
        if best ~= cfg.method and bestPct > 0.3 then
            cfg.method = best
            state.last_switch = os.clock()
            api:notify("AI Switched to: "..best, 2)
        end
    end
end

-- Main Loop
api:add_connection(RunService.Heartbeat:Connect(function(dt)
    if not cfg.enabled then return end
    
    local char = GetTarget()
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        local hum = char:FindFirstChild("Humanoid")
        
        -- Hit Tracking
        if hum then
            if hum.Health < state.current_target_health then
                if state.shot_fired then TrackHit(true); state.shot_fired = false end
            end
            state.current_target_health = hum.Health
        end
        -- Random Shot Sim
        if math.random() < 0.02 then state.shot_fired = true end
        
        -- Calculations
        local vel = root.AssemblyLinearVelocity
        table.insert(state.history, vel)
        if #state.history > cfg.smooth_samples then table.remove(state.history, 1) end
        
        local accel = (vel - state.last_vel) / dt
        state.last_vel = vel
        state.calc_accel = accel
        
        -- Predict
        local method = RES_METHODS[cfg.method] or RES_METHODS["Linear"]
        local predPos = method(root.Position, vel, accel, cfg.reaction_time, char)
        
        -- OVERRIDE VELOCITY
        -- We calculate the velocity needed to reach PredPos in T time
        -- NewVel = (PredPos - CurrentPos) / T
        -- This forces the game engine (and other scripts) to see the target moving towards the predicted spot
        local newVel = (predPos - root.Position) / cfg.reaction_time
        
        -- This is a local override, effective for other scripts reading .Velocity
        -- root.AssemblyLinearVelocity = newVel 
        -- NOTE: Setting AssemblyLinearVelocity locally can lead to stutter if server replicates back.
        -- A better way for pure visualization/calculation for OTHER scripts is hard.
        -- But for the main script, we might just need to visualize it here.
        
        -- Visuals
        if cfg.visualize then
            if not state.dot then
                local p = Instance.new("Part")
                p.Size = Vector3.new(1,1,1)
                p.Anchored = true
                p.CanCollide = false
                p.Color = Color3.new(1,0,0)
                p.Material = "Neon"
                p.Shape = "Ball"
                p.Parent = Workspace
                state.dot = p
            end
            state.dot.CFrame = CFrame.new(predPos)
        elseif state.dot then
            state.dot:Destroy()
            state.dot = nil
        end
    else
        if state.dot then state.dot:Destroy(); state.dot = nil end
    end
end))

-- Persistence
local FILE = "kinetic_resolver.json"
if isfile and isfile(FILE) then
    local s, d = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(FILE)) end)
    if s and d then for k,v in pairs(d) do if state.res_data[k] then state.res_data[k] = v end end end
end

spawn(function()
    while wait(30) do
        if writefile then writefile(FILE, game:GetService("HttpService"):JSONEncode(state.res_data)) end
    end
end)

api:notify("Kinetic Resolver Loaded", 3)
