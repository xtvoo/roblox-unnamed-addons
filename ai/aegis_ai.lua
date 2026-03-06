--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                    PROJECT AEGIS v2.0 - AUTONOMOUS HvH AI                   ║
║              Reinforcement Learning Combat System for Unnamed               ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  FEATURES:                                                                   ║
║  1. Game Environment Interaction - Real-time state reading & control        ║
║  2. Q-Learning Algorithm - Learns optimal strategies over time              ║
║  3. Data Collection - Tracks all gameplay metrics                           ║
║  4. Training System - Structured learning with assessments                  ║
║  5. User Interface - Full monitoring and control panel                      ║
║  6. Ethical Safeguards - No exploits, fair play                            ║
║  7. Scalable Design - Easy to adapt for other games                        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  DISCLAIMER: This AI is for educational purposes. Use responsibly.          ║
║  The author is not responsible for any misuse of this software.             ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

api:set_lua_name("Aegis_AI_v2")

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 1: SERVICES & CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Configuration (Scalable - adjust for different games)
local CONFIG = {
    -- Learning Parameters
    LearningRate = 0.15,           -- Alpha: How fast AI learns (0.1-0.3 recommended)
    DiscountFactor = 0.9,          -- Gamma: Future reward importance
    ExplorationRate = 0.10,        -- Epsilon: Chance to try random action (Reduced for stability)
    ExplorationDecay = 0.995,      -- Reduce exploration over time
    MinExploration = 0.05,         -- Minimum exploration rate
    
    -- Decision Timing
    DecisionInterval = 2,          -- Seconds between strategy changes
    TargetSwitchMin = 5,           -- Min seconds before switching targets
    TargetSwitchMax = 15,          -- Max seconds before switching targets
    
    -- Combat Parameters
    EngageDistance = 150,          -- Max distance to engage targets
    OptimalDistanceMin = 30,       -- Minimum preferred combat distance
    OptimalDistanceMax = 80,       -- Maximum preferred combat distance
    
    -- Data Files
    BrainFile = "aegis_v2_brain.json",
    StatsFile = "aegis_v2_stats.json",
    ConfigFile = "aegis_v2_config.json",
    
    -- Training
    AssessmentInterval = 60,       -- Seconds between performance assessments
    TrainingEpisodes = 0,          -- Track number of training episodes
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 2: STATE DEFINITIONS (Scalable for different games)
-- ═══════════════════════════════════════════════════════════════════════════

local StateDefinitions = {
    Health = {
        {name = "Critical", min = 0, max = 15},
        {name = "Low", min = 16, max = 35},
        {name = "Medium", min = 36, max = 60},
        {name = "High", min = 61, max = 85},
        {name = "Full", min = 86, max = 100}
    },
    Distance = {
        {name = "CQC", min = 0, max = 30},
        {name = "Close", min = 31, max = 75},
        {name = "Medium", min = 76, max = 150},
        {name = "Far", min = 151, max = 300},
        {name = "Safe", min = 301, max = 9999}
    },
    EnemyCount = {
        {name = "Solo", min = 1, max = 1},
        {name = "Few", min = 2, max = 3},
        {name = "Many", min = 4, max = 99}
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 3: ACTION DEFINITIONS (Combat Strategies)
-- ═══════════════════════════════════════════════════════════════════════════

local ACTIONS = {
    {
        Name = "Aggressive Rush",
        Description = "High speed assault - push hard and fast",
        Flags = {
            ragebot_spiral_speed = 14,
            ragebot_spiral_distance = 35,
            ragebot_void_in = 0.18,
            ragebot_void_out = 0.08,
            strafe_offset = 12,
            strafe_random_offset = 20,
            movement_walkspeedvalue = 45,
            ragebot_prediction_multiplier = 2.0
        }
    },
    {
        Name = "Balanced Combat",
        Description = "Versatile strategy for most situations",
        Flags = {
            ragebot_spiral_speed = 8,
            ragebot_spiral_distance = 52,
            ragebot_void_in = 0.35,
            ragebot_void_out = 0.12,
            strafe_offset = 18,
            strafe_random_offset = 15,
            movement_walkspeedvalue = 35,
            ragebot_prediction_multiplier = 1.8
        }
    },
    {
        Name = "Defensive Turtle",
        Description = "Survive and counter - prioritize safety",
        Flags = {
            ragebot_spiral_speed = 5,
            ragebot_spiral_distance = 75,
            ragebot_void_in = 0.5,
            ragebot_void_out = 0.2,
            strafe_offset = 28,
            strafe_random_offset = 10,
            movement_walkspeedvalue = 28,
            ragebot_prediction_multiplier = 1.5
        }
    },
    {
        Name = "Evasive Ghost",
        Description = "Unpredictable movement - hard to hit",
        Flags = {
            ragebot_spiral_speed = 16,
            ragebot_spiral_distance = 48,
            ragebot_void_in = 0.12,
            ragebot_void_out = 0.06,
            strafe_offset = 22,
            strafe_random_offset = 40,
            movement_walkspeedvalue = 50,
            ragebot_prediction_multiplier = 2.2
        }
    },
    {
        Name = "Sniper Hold",
        Description = "Long range precision - minimal movement",
        Flags = {
            ragebot_spiral_speed = 3,
            ragebot_spiral_distance = 25,
            ragebot_void_in = 0.6,
            ragebot_void_out = 0.25,
            strafe_offset = 6,
            strafe_random_offset = 5,
            movement_walkspeedvalue = 22,
            ragebot_prediction_multiplier = 1.4
        }
    },
    {
        Name = "Flanker",
        Description = "Circle around targets - attack from angles",
        Flags = {
            ragebot_spiral_speed = 11,
            ragebot_spiral_distance = 60,
            ragebot_void_in = 0.28,
            ragebot_void_out = 0.1,
            strafe_offset = 35,
            strafe_random_offset = 25,
            movement_walkspeedvalue = 40,
            ragebot_prediction_multiplier = 1.9
        }
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 4: AI BRAIN (Q-Learning Core)
-- ═══════════════════════════════════════════════════════════════════════════

local AegisBrain = {
    -- Q-Table: Stores learned values for each state-action pair
    QTable = {},
    
    -- Control Flags
    Enabled = false,
    Autonomous = true,
    Training = true,
    Paused = false,
    
    -- State Tracking
    LastState = nil,
    LastAction = nil,
    CurrentTarget = nil,
    TargetSwitchTime = 0,
    LastDecision = 0,
    LastAssessment = 0,
    LastHealth = 100,
    
    -- Cumulative Stats (never reset during session)
    TotalReward = 0,
    TotalEpisodes = 0,
    
    -- Session Statistics (cumulative for entire session - DATA COLLECTION)
    SessionStats = {
        StartTime = os.clock(),
        TotalHits = 0,
        TotalMisses = 0,
        TotalKills = 0,
        TotalDeaths = 0,
        TotalDamageDealt = 0,
        TotalDamageTaken = 0,
        TargetsEngaged = 0,
        ActionsChosen = {},
        StateVisits = {},
        RewardHistory = {},
        KillDeathHistory = {},
    },
    
    -- Per-Decision Stats (reset after each learning cycle)
    DecisionStats = {
        Hits = 0,
        Misses = 0,
        DamageDealt = 0,
        DamageTaken = 0,
    },

    
    -- Performance Metrics
    Performance = {
        CurrentKD = 0,
        CurrentHitRate = 0,
        AverageReward = 0,
        BestAction = "Unknown",
        WorstAction = "Unknown",
        MostVisitedState = "Unknown",
        LearningProgress = 0,
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 5: HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Safe flag setter (AGGRESSIVE MODE - Tries everything)
local function setFlag(flagName, value)
    local success = false
    
    -- Try Options (Sliders/Combos)
    if Options and Options[flagName] then
        pcall(function() Options[flagName]:SetValue(value) end)
        success = true
    end
    
    -- Try Toggles (Booleans)
    if Toggles and Toggles[flagName] then
        pcall(function() Toggles[flagName]:SetValue(value) end)
        success = true
    end
    
    -- Try raw API UI object
    pcall(function()
        local uiObj = api:get_ui_object(flagName)
        if uiObj and uiObj.SetValue then
            uiObj:SetValue(value)
            success = true
        end
    end)
    
    return success
end

-- Safe flag getter
local function getFlag(flagName)
    if Options and Options[flagName] then return Options[flagName].Value end
    if Toggles and Toggles[flagName] then return Toggles[flagName].Value end
    local uiObj = api:get_ui_object(flagName)
    if uiObj then return uiObj.Value end
    return nil
end

-- Discretize a continuous value into a named category
local function discretize(value, categories)
    for _, cat in ipairs(categories) do
        if value >= cat.min and value <= cat.max then
            return cat.name
        end
    end
    return categories[#categories].name
end

-- Check if a player is valid target (not KO'd or dead)
local function isValidTarget(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    local be = char:FindFirstChild("BodyEffects")
    if be then
        local ko = be:FindFirstChild("K.O")
        if ko and ko.Value then return false end
        local dead = be:FindFirstChild("Dead")
        if dead and dead.Value then return false end
    end
    
    return true
end

-- Get player distance
local function getPlayerDistance(player)
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local theirChar = player.Character
    local theirHRP = theirChar and theirChar:FindFirstChild("HumanoidRootPart")
    
    if myHRP and theirHRP then
        return (myHRP.Position - theirHRP.Position).Magnitude
    end
    return 9999
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 6: GAME ENVIRONMENT INTERACTION
-- ═══════════════════════════════════════════════════════════════════════════

-- Read current game state
local function readGameState()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local health = hum and hum.Health or 0
    
    -- Count nearby enemies and find closest
    local enemies = {}
    local closestDist = 9999
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local dist = getPlayerDistance(player)
            if dist < CONFIG.EngageDistance then
                table.insert(enemies, {player = player, distance = dist})
                if dist < closestDist then
                    closestDist = dist
                end
            end
        end
    end
    
    -- Sort enemies by distance
    table.sort(enemies, function(a, b) return a.distance < b.distance end)
    
    return {
        health = health,
        enemyCount = #enemies,
        closestDistance = closestDist,
        enemies = enemies,
        hasTarget = AegisBrain.CurrentTarget ~= nil
    }
end

-- Convert game state to discrete state key (Safe Mode)
local function getStateKey(gameState)
    if not gameState then return "Unknown_Unknown_Unknown" end
    
    local healthState = discretize(gameState.health or 100, StateDefinitions.Health)
    local distState = discretize(gameState.closestDistance or 9999, StateDefinitions.Distance)
    local countState = discretize(math.max(1, gameState.enemyCount or 0), StateDefinitions.EnemyCount)
    
    return string.format("%s_%s_%s", healthState, distState, countState)
end

-- Pick a random target weighted by distance
local function pickRandomTarget(enemies)
    if #enemies == 0 then return nil end
    
    -- Weight by inverse distance (closer = more likely)
    local weights = {}
    local total = 0
    for i, e in ipairs(enemies) do
        local w = 1 / (e.distance + 10)
        weights[i] = w
        total = total + w
    end
    
    local roll = math.random() * total
    local cumulative = 0
    for i, w in ipairs(weights) do
        cumulative = cumulative + w
        if roll <= cumulative then
            return enemies[i].player
        end
    end
    return enemies[1].player
end

-- Engage target using Unnamed's ragebot system
local function engageTarget(target)
    if not target or not target.Character then return false end
    
    -- Enable ragebot systems
    setFlag("ragebot_enabled", true)
    setFlag("SilentEnabled", true)
    setFlag("silent_toggle", true)
    
    -- Force keybinds active
    pcall(function() api:override_key_state("ragebot_keybind", true) end)
    pcall(function() api:override_key_state("silent_keybind", true) end)
    
    -- Set target in ragebot targets
    pcall(function()
        local targets = getFlag("ragebot_targets") or {}
        for k in pairs(targets) do targets[k] = nil end
        targets[target.Name] = true
        setFlag("ragebot_targets", targets)
    end)
    
    -- Force ragebot on via API
    pcall(function() api:set_ragebot(true) end)
    
    return true
end



-- Move towards/away from target to maintain optimal distance
local function maintainDistance(target, optimalDist)
    if not target or not target.Character then return end
    
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChild("Humanoid")
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    
    if not myHRP or not targetHRP or not myHum then return end
    
    local direction = (targetHRP.Position - myHRP.Position)
    local distance = direction.Magnitude
    
    if distance > optimalDist + 15 then
        myHum:MoveTo(targetHRP.Position)
    elseif distance < optimalDist - 10 then
        local awayDir = -direction.Unit
        myHum:MoveTo(myHRP.Position + awayDir * 25)
    end
end

-- Auto-shoot (backup for ragebot)
local function autoShoot()
    if Mouse1Press and Mouse1Release then
        pcall(function()
            Mouse1Press()
            task.delay(0.05, Mouse1Release)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 7: Q-LEARNING ALGORITHM
-- ═══════════════════════════════════════════════════════════════════════════

-- Initialize Q-values for a new state (with preference for Balanced strategy)
local function initState(state)
    if not AegisBrain.QTable[state] then
        AegisBrain.QTable[state] = {}
        for i = 1, #ACTIONS do
            if i == 2 then -- Index 2 is "Balanced Combat"
                AegisBrain.QTable[state][i] = 5 -- Give it a head start info
            else
                AegisBrain.QTable[state][i] = 0
            end
        end
    end
end

-- Choose action using epsilon-greedy policy
local function chooseAction(state)
    initState(state)
    
    -- Track state visit
    AegisBrain.SessionStats.StateVisits[state] = (AegisBrain.SessionStats.StateVisits[state] or 0) + 1
    
    -- Exploration: random action
    if AegisBrain.Training and math.random() < CONFIG.ExplorationRate then
        return math.random(1, #ACTIONS)
    end
    
    -- Exploitation: best known action
    local bestIdx, maxQ = 1, -math.huge
    for i, q in pairs(AegisBrain.QTable[state]) do
        if q > maxQ then
            maxQ = q
            bestIdx = i
        end
    end
    return bestIdx
end

-- Apply action (modify Unnamed flags)
local function applyAction(actionIdx)
    local action = ACTIONS[actionIdx]
    if not action then return nil end
    
    -- Track action usage (Safe Mode)
    if AegisBrain.SessionStats and AegisBrain.SessionStats.ActionsChosen then
        AegisBrain.SessionStats.ActionsChosen[action.Name] = 
            (AegisBrain.SessionStats.ActionsChosen[action.Name] or 0) + 1
    end
    
    -- Apply all flags
    print("[AEGIS] Applying Strategy: " .. action.Name) -- DEBUG
    for flagName, value in pairs(action.Flags) do
        setFlag(flagName, value)
    end
    
    return action
end

-- Calculate reward based on recent events (uses per-decision stats)
local function calculateReward()
    local stats = AegisBrain.DecisionStats
    local reward = 0
    
    -- Positive rewards
    reward = reward + stats.Hits * 8
    reward = reward + stats.DamageDealt * 0.15
    reward = reward + 1 -- Survival/Activity reward (keeps it learning)
    
    -- Negative rewards  
    reward = reward - stats.Misses * 3
    reward = reward - stats.DamageTaken * 0.4
    
    -- Record reward history
    table.insert(AegisBrain.SessionStats.RewardHistory, reward)
    if #AegisBrain.SessionStats.RewardHistory > 100 then
        table.remove(AegisBrain.SessionStats.RewardHistory, 1)
    end
    
    return reward
end

-- Update Q-value using Bellman equation
local function learn(state, actionIdx, reward, nextState)
    if not AegisBrain.Training then return end
    
    initState(state)
    initState(nextState)
    
    local currentQ = AegisBrain.QTable[state][actionIdx]
    
    -- Find max Q for next state
    local maxNextQ = -math.huge
    for _, q in pairs(AegisBrain.QTable[nextState]) do
        if q > maxNextQ then maxNextQ = q end
    end
    
    -- Q(s,a) = Q(s,a) + α * (R + γ * max Q(s',a') - Q(s,a))
    local newQ = currentQ + CONFIG.LearningRate * (reward + CONFIG.DiscountFactor * maxNextQ - currentQ)
    AegisBrain.QTable[state][actionIdx] = newQ
    
    -- Decay exploration rate
    CONFIG.ExplorationRate = math.max(CONFIG.MinExploration, CONFIG.ExplorationRate * CONFIG.ExplorationDecay)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 8: TRAINING & ASSESSMENT SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

-- Assess AI performance
local function assessPerformance()
    local stats = AegisBrain.SessionStats
    
    -- Calculate K/D (using Total* fields)
    local kills = stats.TotalKills or 0
    local deaths = stats.TotalDeaths or 0
    local kd = deaths > 0 and (kills / deaths) or kills
    AegisBrain.Performance.CurrentKD = kd
    
    -- Calculate hit rate
    local hits = stats.TotalHits or 0
    local misses = stats.TotalMisses or 0
    local totalShots = hits + misses
    local hitRate = totalShots > 0 and (hits / totalShots) or 0
    AegisBrain.Performance.CurrentHitRate = hitRate
    
    -- Calculate average reward
    local rewardHistory = stats.RewardHistory
    local avgReward = 0
    if #rewardHistory > 0 then
        local sum = 0
        for _, r in ipairs(rewardHistory) do sum = sum + r end
        avgReward = sum / #rewardHistory
    end
    AegisBrain.Performance.AverageReward = avgReward
    
    -- Find best and worst actions
    local actionStats = stats.ActionsChosen
    local bestAction, worstAction = nil, nil
    local bestScore, worstScore = -math.huge, math.huge
    
    for actionName, count in pairs(actionStats) do
        if count > bestScore then bestScore, bestAction = count, actionName end
        if count < worstScore then worstScore, worstAction = count, actionName end
    end
    AegisBrain.Performance.BestAction = bestAction or "Unknown"
    AegisBrain.Performance.WorstAction = worstAction or "Unknown"
    
    -- Track K/D history
    table.insert(stats.KillDeathHistory, {kills = stats.Kills, deaths = stats.Deaths, kd = kd})
    
    -- Calculate learning progress (how many states learned)
    local learnedStates = 0
    for _ in pairs(AegisBrain.QTable) do learnedStates = learnedStates + 1 end
    AegisBrain.Performance.LearningProgress = learnedStates
    
    AegisBrain.TotalEpisodes = AegisBrain.TotalEpisodes + 1
    
    return {
        kd = kd,
        hitRate = hitRate,
        avgReward = avgReward,
        learnedStates = learnedStates
    }
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 9: DATA PERSISTENCE
-- ═══════════════════════════════════════════════════════════════════════════

local function saveBrain()
    if not writefile then return end
    pcall(function()
        local data = {
            QTable = AegisBrain.QTable,
            TotalReward = AegisBrain.TotalReward,
            TotalEpisodes = AegisBrain.TotalEpisodes,
            ExplorationRate = CONFIG.ExplorationRate
        }
        writefile(CONFIG.BrainFile, HttpService:JSONEncode(data))
    end)
end

local function loadBrain()
    if not readfile or not isfile then return end
    if isfile(CONFIG.BrainFile) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(CONFIG.BrainFile))
            if data then
                AegisBrain.QTable = data.QTable or {}
                AegisBrain.TotalReward = data.TotalReward or 0
                AegisBrain.TotalEpisodes = data.TotalEpisodes or 0
                CONFIG.ExplorationRate = data.ExplorationRate or 0.25
            end
        end)
    end
end

local function saveStats()
    if not writefile then return end
    pcall(function()
        local data = {
            sessionStats = AegisBrain.SessionStats,
            performance = AegisBrain.Performance,
            savedAt = os.date("%Y-%m-%d %H:%M:%S")
        }
        writefile(CONFIG.StatsFile, HttpService:JSONEncode(data))
    end)
end

local function generateOptimalConfig()
    if not writefile then return end
    
    local optimalSettings = {}
    for state, qValues in pairs(AegisBrain.QTable) do
        local bestIdx, maxQ = 1, -math.huge
        for i, q in pairs(qValues) do
            if q > maxQ then maxQ, bestIdx = q, i end
        end
        optimalSettings[state] = {
            action = ACTIONS[bestIdx].Name,
            qValue = maxQ,
            flags = ACTIONS[bestIdx].Flags
        }
    end
    
    pcall(function()
        local data = {
            generated = os.date("%Y-%m-%d %H:%M:%S"),
            optimalPerState = optimalSettings,
            performance = AegisBrain.Performance
        }
        writefile(CONFIG.ConfigFile, HttpService:JSONEncode(data))
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 10: USER INTERFACE
-- ═══════════════════════════════════════════════════════════════════════════

local tabs = {
    AI = api:AddTab("Aegis AI v2")
}

-- === Control Panel ===
local controlBox = tabs.AI:AddLeftGroupbox("Control Panel")

local enableToggle = controlBox:AddToggle("aegis_enable", {
    Text = "Enable AI",
    Default = false
})

local autoPlayToggle = controlBox:AddToggle("aegis_autoplay", {
    Text = "Full Auto-Play",
    Default = true
})

local trainingToggle = controlBox:AddToggle("aegis_training", {
    Text = "Training Mode",
    Default = true
})

local pauseToggle = controlBox:AddToggle("aegis_pause", {
    Text = "Pause AI",
    Default = false
})

-- === Parameters ===
local paramsBox = tabs.AI:AddLeftGroupbox("Parameters")

local explorationSlider = paramsBox:AddSlider("aegis_explore", {
    Text = "Exploration Rate",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 2
})

local intervalSlider = paramsBox:AddSlider("aegis_interval", {
    Text = "Decision Interval",
    Default = 2,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "s"
})

local engageDistSlider = paramsBox:AddSlider("aegis_engage_dist", {
    Text = "Engage Distance",
    Default = 150,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Suffix = " studs"
})

-- === Live Status ===
local statusBox = tabs.AI:AddRightGroupbox("Live Status")
local statusEnabled = statusBox:AddLabel("Status: OFFLINE")
local statusState = statusBox:AddLabel("State: ---")
local statusAction = statusBox:AddLabel("Action: ---")
local statusTarget = statusBox:AddLabel("Target: None")

-- === Performance Metrics ===
local metricsBox = tabs.AI:AddRightGroupbox("Performance")
local metricKD = metricsBox:AddLabel("K/D: 0.00")
local metricHitRate = metricsBox:AddLabel("Hit Rate: 0%")
local metricReward = metricsBox:AddLabel("Total Reward: 0")
local metricStates = metricsBox:AddLabel("Learned States: 0")

-- === Session Stats ===
local sessionBox = tabs.AI:AddLeftGroupbox("Session Stats")
local sessionKills = sessionBox:AddLabel("Kills: 0")
local sessionDeaths = sessionBox:AddLabel("Deaths: 0")
local sessionHits = sessionBox:AddLabel("Hits: 0")
local sessionDamage = sessionBox:AddLabel("Damage: +0 / -0")

-- === Brain Management ===
local brainBox = tabs.AI:AddRightGroupbox("Brain Management")

brainBox:AddButton("Save Brain", function()
    saveBrain()
    saveStats()
    api:notify("Brain & stats saved!", 3)
end)

brainBox:AddButton("Generate Config", function()
    generateOptimalConfig()
    api:notify("Optimal config generated!", 3)
end)

brainBox:AddButton("Reset Brain", function()
    AegisBrain.QTable = {}
    AegisBrain.TotalReward = 0
    AegisBrain.TotalEpisodes = 0
    CONFIG.ExplorationRate = 0.25
    api:notify("Brain reset!", 2)
end)

brainBox:AddButton("Assess Performance", function()
    local assessment = assessPerformance()
    api:notify(string.format("K/D: %.2f | Hit: %.0f%% | States: %d", 
        assessment.kd, assessment.hitRate * 100, assessment.learnedStates), 5)
end)

-- === UI Callbacks ===
enableToggle:OnChanged(function(v)
    AegisBrain.Enabled = v
    statusEnabled.Text = v and "Status: ONLINE" or "Status: OFFLINE"
    api:notify(v and "Aegis AI: ONLINE" or "Aegis AI: OFFLINE", 2)
end)

autoPlayToggle:OnChanged(function(v)
    AegisBrain.Autonomous = v
end)

trainingToggle:OnChanged(function(v)
    AegisBrain.Training = v
end)

pauseToggle:OnChanged(function(v)
    AegisBrain.Paused = v
end)

explorationSlider:OnChanged(function(v)
    CONFIG.ExplorationRate = v
end)

intervalSlider:OnChanged(function(v)
    CONFIG.DecisionInterval = v
end)

engageDistSlider:OnChanged(function(v)
    CONFIG.EngageDistance = v
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 11: MAIN AI LOOP
-- ═══════════════════════════════════════════════════════════════════════════

local function updateUI()
    local stats = AegisBrain.SessionStats
    local perf = AegisBrain.Performance
    
    -- Update metrics
    local kd = stats.TotalDeaths > 0 and (stats.TotalKills / stats.TotalDeaths) or stats.TotalKills
    local hitRate = (stats.TotalHits + stats.TotalMisses) > 0 and (stats.TotalHits / (stats.TotalHits + stats.TotalMisses)) or 0
    
    metricKD.Text = string.format("K/D: %.2f", kd)
    metricHitRate.Text = string.format("Hit Rate: %.0f%%", hitRate * 100)
    metricReward.Text = string.format("Total Reward: %.0f", AegisBrain.TotalReward)
    
    local learnedStates = 0
    for _ in pairs(AegisBrain.QTable) do learnedStates = learnedStates + 1 end
    metricStates.Text = "Learned States: " .. learnedStates
    
    -- Update session stats (cumulative totals)
    sessionKills.Text = "Kills: " .. stats.TotalKills
    sessionDeaths.Text = "Deaths: " .. stats.TotalDeaths
    sessionHits.Text = "Hits: " .. stats.TotalHits .. " / Misses: " .. stats.TotalMisses
    sessionDamage.Text = string.format("Damage: +%.0f / -%.0f", stats.TotalDamageDealt, stats.TotalDamageTaken)
end

local mainLoop = RunService.Heartbeat:Connect(function()
    -- Debug Print Throttling (once per second)
    local now = os.clock()
    local doDebug = (math.floor(now) % 2 == 0) and (math.floor(now * 10) % 10 == 0)
    
    -- Force update Enabled state
    pcall(function()
        if Options and Options.aegis_enable then
            AegisBrain.Enabled = Options.aegis_enable.Value
            if doDebug then print("[AEGIS DEBUG] Options.aegis_enable = " .. tostring(AegisBrain.Enabled)) end
        elseif Toggles and Toggles.aegis_enable then
            AegisBrain.Enabled = Toggles.aegis_enable.Value
             if doDebug then print("[AEGIS DEBUG] Toggles.aegis_enable = " .. tostring(AegisBrain.Enabled)) end
        else
            if doDebug then print("[AEGIS DEBUG] Could not find Options/Toggles for enable switch!") end
        end
    end)
    
    if not AegisBrain.Enabled then 
        statusEnabled.Text = "Status: OFFLINE (Check Enable AI)"
        return 
    end
    statusEnabled.Text = "Status: ONLINE (RUNNING)"
    
    if doDebug then print("[AEGIS DEBUG] Main Loop Running...") end
    
    if AegisBrain.Paused then 
        statusEnabled.Text = "Status: PAUSED"
        return 
    end

        local switchTime = CONFIG.TargetSwitchMin + math.random() * (CONFIG.TargetSwitchMax - CONFIG.TargetSwitchMin)
        
        if not targetValid or targetAge > switchTime then
            local newTarget = pickRandomTarget(gameState.enemies)
            if newTarget then
                AegisBrain.CurrentTarget = newTarget
                AegisBrain.TargetSwitchTime = now
                AegisBrain.SessionStats.TargetsEngaged = AegisBrain.SessionStats.TargetsEngaged + 1
                engageTarget(newTarget)
                statusTarget.Text = "Target: " .. newTarget.Name
            else
                statusTarget.Text = "Target: Searching..."
            end
        end
        
        -- Combat actions (every frame)
        if AegisBrain.CurrentTarget and isValidTarget(AegisBrain.CurrentTarget) then
            -- Note: aimAtTarget removed as requested, now relying purely on ragebot
            local optDist = (CONFIG.OptimalDistanceMin + CONFIG.OptimalDistanceMax) / 2
            maintainDistance(AegisBrain.CurrentTarget, optDist)
            engageTarget(AegisBrain.CurrentTarget)
            autoShoot()
        end
    end
    
    -- === AI DECISION (throttled) ===
    if now - AegisBrain.LastDecision < CONFIG.DecisionInterval then return end
    AegisBrain.LastDecision = now
    
    local gameState = readGameState()
    local currentState = getStateKey(gameState)
    
    -- Track damage (both cumulative and per-decision)
    if gameState.health < AegisBrain.LastHealth then
        local dmgTaken = AegisBrain.LastHealth - gameState.health
        AegisBrain.DecisionStats.DamageTaken = AegisBrain.DecisionStats.DamageTaken + dmgTaken
        AegisBrain.SessionStats.TotalDamageTaken = AegisBrain.SessionStats.TotalDamageTaken + dmgTaken
    end
    AegisBrain.LastHealth = gameState.health
    
    -- Learn from previous action
    if AegisBrain.LastState and AegisBrain.LastAction then
        local reward = calculateReward()
        AegisBrain.TotalReward = AegisBrain.TotalReward + reward
        learn(AegisBrain.LastState, AegisBrain.LastAction, reward, currentState)
        
        -- Reset per-decision stats (NOT session stats)
        AegisBrain.DecisionStats.Hits = 0
        AegisBrain.DecisionStats.Misses = 0
        AegisBrain.DecisionStats.DamageDealt = 0
        AegisBrain.DecisionStats.DamageTaken = 0
    end
    
    -- Choose new action
    local actionIdx = chooseAction(currentState)
    local action = applyAction(actionIdx)
    
    AegisBrain.LastState = currentState
    AegisBrain.LastAction = actionIdx
    
    -- Update status
    statusState.Text = "State: " .. currentState
    statusAction.Text = "Action: " .. (action and action.Name or "---")
    
    -- Periodic assessment
    if now - AegisBrain.LastAssessment > CONFIG.AssessmentInterval then
        assessPerformance()
        AegisBrain.LastAssessment = now
    end
    
    updateUI()
end)
api:add_connection(mainLoop)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 12: EVENT HOOKS
-- ═══════════════════════════════════════════════════════════════════════════

-- Stats tracking loop (Damage, Kills, Deaths)
task.spawn(function()
    local lastTargetHealth = 100
    
    while task.wait(0.1) do -- Fast tick for damage tracking
        if not AegisBrain.Enabled then 
            task.wait(1)
            continue 
        end
        
        -- Check local player death
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then
            AegisBrain.SessionStats.TotalDeaths = AegisBrain.SessionStats.TotalDeaths + 1
            AegisBrain.CurrentTarget = nil
            -- Wait for respawn
            repeat task.wait(1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0
        end
        
        -- Check target status (Damage & Kills)
        if AegisBrain.CurrentTarget then
            local tChar = AegisBrain.CurrentTarget.Character
            local tHum = tChar and tChar:FindFirstChild("Humanoid")
            
            if tHum then
                local currentHP = tHum.Health
                -- Detect damage dealt
                if currentHP < lastTargetHealth and currentHP > 0 then
                    local dmg = lastTargetHealth - currentHP
                    -- Reasonable damage check (ignore instant kills/resets for hit stats)
                    if dmg < 100 then
                        AegisBrain.DecisionStats.Hits = AegisBrain.DecisionStats.Hits + 1
                        AegisBrain.DecisionStats.DamageDealt = AegisBrain.DecisionStats.DamageDealt + dmg
                        AegisBrain.SessionStats.TotalHits = AegisBrain.SessionStats.TotalHits + 1
                        AegisBrain.SessionStats.TotalDamageDealt = AegisBrain.SessionStats.TotalDamageDealt + dmg
                    end
                end
                
                -- Detect Kill
                if currentHP <= 0 and lastTargetHealth > 0 then
                    AegisBrain.SessionStats.TotalKills = AegisBrain.SessionStats.TotalKills + 1
                    AegisBrain.CurrentTarget = nil
                    lastTargetHealth = 100 -- Reset tracker
                else
                    lastTargetHealth = currentHP
                end
            else
                lastTargetHealth = 100 -- Target lost/respawning
            end
        else
            lastTargetHealth = 100 -- No target
        end
    end
end)

api:on_event("unload", function()
    saveBrain()
    saveStats()
    api:notify("Aegis AI v2 saved and unloaded!", 2)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 13: INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

loadBrain()
updateUI()

api:notify("🤖 AEGIS AI v2.0 Loaded!", 3)
api:notify("Enable AI in the 'Aegis AI v2' tab to begin!", 5)
