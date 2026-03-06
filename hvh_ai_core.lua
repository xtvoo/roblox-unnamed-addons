--[[
    Project Aegis - AI Core
    Reinforcement Learning (Q-Learning) Module for HvH
    
    This module implements a Q-Learning agent that learns optimal strategies
    based on game state (Health, Start, Performance).
]]

local Aegis = {}
Aegis.__index = Aegis

-- ==================== CONFIGURATION ====================
local CONFIG = {
    LearningRate = 0.1, -- Alpha
    DiscountFactor = 0.9, -- Gamma
    ExplorationRate = 0.2, -- Epsilon (Probability of random action)
    SaveFile = "hvh_aegis_data.json"
}

-- ==================== DEFINITIONS ====================

-- STATES
-- Format: "Health_Distance_Pressure"
-- Health: High (>70), Mid (30-70), Low (<30)
-- Distance: Close (<50), Mid (50-150), Far (>150)
-- Pressure: Safe (No aimers), UnderFire (Being aimed at)

-- ACTIONS
-- Different combinations of Strafe Mode and Resolver Mode
Aegis.Actions = {
    { Name = "Aggressive", Strafe = "Quantum", Resolver = "Aggressive", Speed = 16, DistSpam = false },
    { Name = "Tactical", Strafe = "Helix3D", Resolver = "Adaptive", Speed = 12, DistSpam = false },
    { Name = "Evasive", Strafe = "Ghost", Resolver = "Predictive", Speed = 20, DistSpam = true },
    { Name = "Turtle", Strafe = "Orbit", Resolver = "Basics", Speed = 8, DistSpam = false },
    { Name = "Unpredictable", Strafe = "Unpredictable", Resolver = "Aggressive", Speed = 14, DistSpam = false }
}

-- ==================== CORE FUNCTIONS ====================

function Aegis.new()
    local self = setmetatable({}, Aegis)
    self.QTable = {} -- [State][ActionIndex] = Value
    self.LastState = nil
    self.LastActionIndex = nil
    self.TotalReward = 0
    self.Enabled = false
    self.Training = true
    return self
end

function Aegis:GetState(localPlayer, enemies)
    -- Discretize game state into a string key
    if not localPlayer or not localPlayer.Character then return "Unknown" end
    
    local hum = localPlayer.Character:FindFirstChild("Humanoid")
    if not hum then return "Dead" end
    
    -- 1. Health
    local hp = hum.Health
    local hpState = "High"
    if hp < 30 then hpState = "Low"
    elseif hp < 70 then hpState = "Mid" end
    
    -- 2. Distance to closest enemy
    local minDist = 9999
    local pressure = "Safe"
    
    if enemies then
        for _, enemy in pairs(enemies) do
            if enemy and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                local myPos = localPlayer.Character.HumanoidRootPart.Position
                local dist = (enemy.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist < minDist then minDist = dist end
                
                -- Check if aiming at us (simplified)
                -- (In real integration, we'd pass the specific 'isAimingAtMe' result)
            end
        end
    end
    
    local distState = "Far"
    if minDist < 50 then distState = "Close"
    elseif minDist < 150 then distState = "Mid" end
    
    -- Return composite key
    return string.format("%s_%s", hpState, distState)
end

function Aegis:ChooseAction(state)
    -- Initialize state in QTable if new
    if not self.QTable[state] then
        self.QTable[state] = {}
        for i = 1, #Aegis.Actions do
            self.QTable[state][i] = 0.0 -- Initial Q-values
        end
    end
    
    -- Exploration vs Exploitation
    if self.Training and math.random() < CONFIG.ExplorationRate then
        -- Random action
        local idx = math.random(1, #Aegis.Actions)
        return idx, Aegis.Actions[idx]
    else
        -- Best action
        local bestIdx = 1
        local maxQ = -9999
        for i, q in pairs(self.QTable[state]) do
            if q > maxQ then
                maxQ = q
                bestIdx = i
            end
        end
        return bestIdx, Aegis.Actions[bestIdx]
    end
end

function Aegis:Learn(state, actionIdx, reward, nextState)
    if not self.Training then return end
    if not state or not nextState then return end
    
    local currentQ = self.QTable[state][actionIdx] or 0
    
    -- Ensure next state exists
    if not self.QTable[nextState] then
        self.QTable[nextState] = {}
        for i = 1, #Aegis.Actions do self.QTable[nextState][i] = 0 end
    end
    
    -- Max Q for next state
    local maxNextQ = -9999
    for _, q in pairs(self.QTable[nextState]) do
        if q > maxNextQ then maxNextQ = q end
    end
    
    -- Bellman Equation
    -- Q(s,a) = Q(s,a) + alpha * (R + gamma * maxQ(s',a') - Q(s,a))
    local newQ = currentQ + CONFIG.LearningRate * (reward + CONFIG.DiscountFactor * maxNextQ - currentQ)
    
    self.QTable[state][actionIdx] = newQ
end

function Aegis:Step(localPlayer, enemies, performanceStats)
    if not self.Enabled then return end
    
    local currentState = self:GetState(localPlayer, enemies)
    
    -- Calculate Reward from previous step
    local reward = 0
    if self.LastState and performanceStats then
        if performanceStats.Hit then reward = reward + 10 end
        if performanceStats.Kill then reward = reward + 50 end
        if performanceStats.Death then reward = reward - 50 end
        if performanceStats.DamageTaken > 0 then reward = reward - (performanceStats.DamageTaken * 0.5) end
        
        -- Apply learning
        self:Learn(self.LastState, self.LastActionIndex, reward, currentState)
    end
    
    -- Decide next action
    local actionIdx, action = self:ChooseAction(currentState)
    
    -- Update memory
    self.LastState = currentState
    self.LastActionIndex = actionIdx
    
    return action, currentState
end

-- ==================== PERSISTENCE ====================

function Aegis:Save()
    if not writefile then return end
    local HttpService = game:GetService("HttpService")
    local data = HttpService:JSONEncode(self.QTable)
    pcall(function() writefile(CONFIG.SaveFile, data) end)
end

function Aegis:Load()
    if not readfile or not isfile then return end
    if isfile(CONFIG.SaveFile) then
        local HttpService = game:GetService("HttpService")
        local content = readfile(CONFIG.SaveFile)
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if success and data then
            self.QTable = data
        end
    end
end

return Aegis
