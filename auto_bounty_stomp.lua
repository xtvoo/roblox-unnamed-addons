
-- Auto Bounty Stomper (Unnamed API Version)
if not api then
    warn("Unnamed API not found! Ensure you are running this in the correct environment.")
    return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local ENABLED = true
local TELEPORT_TO_TARGET = true
local STOMP_DELAY = 0.1
local STOMP_HEIGHT = 3.1

-- State
local BountyTargets = {}
local ProcessingTarget = false

-- --- UI SETUP ---
local Tab = api:AddTab("Auto Bounty")
local Group = Tab:AddLeftGroupbox("Main Settings")

Group:AddToggle("EnableAutoBounty", {
    Text = "Enable Auto Bounty",
    Default = true,
    Callback = function(Val)
        ENABLED = Val
    end
})

Group:AddSlider("StompHeight", {
    Text = "Stomp Height",
    Default = 3.1,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Suffix = " studs",
    Callback = function(Val)
        STOMP_HEIGHT = Val
    end
})

Group:AddToggle("TeleportStomp", {
    Text = "Teleport to Target",
    Default = true,
    Callback = function(Val)
        TELEPORT_TO_TARGET = Val
    end
})

-- --- LOGIC ---

-- Function to notify user
local function Notify(msg)
    if api.notify then
        api:notify("AutoBounty: " .. msg, 3)
    else
        print("[AutoBounty] " .. msg)
    end
end

-- Refresh Bounty Targets from Posters
local function RefreshTargets()
    table.clear(BountyTargets)
    local postersFolder = Workspace:WaitForChild("MAP"):WaitForChild("BountyPosters")
    
    if not postersFolder then return end

    for _, poster in ipairs(postersFolder:GetChildren()) do
        -- Navigate hierarchy
        if poster:FindFirstChild("Texts") and 
           poster.Texts:FindFirstChild("PlayerName") and
           poster.Texts.PlayerName:FindFirstChild("SurfaceGui") and
           poster.Texts.PlayerName.SurfaceGui:FindFirstChild("TextLabel") then
            
            local name = poster.Texts.PlayerName.SurfaceGui.TextLabel.Text
            if name and name ~= "Text" and name ~= "" and name ~= LocalPlayer.Name and name ~= LocalPlayer.DisplayName then
                BountyTargets[name] = true
            end
        end
    end
end

-- Function to stomp a target using Glue Logic
local function StompTarget(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    ProcessingTarget = true
    Notify("⚔️ Stomping Bounty: " .. targetPlayer.Name)

    local char = LocalPlayer.Character
    local targetChar = targetPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = hum and hum.RootPart
    
    -- Resolve UpperTorso or Root of target
    local targetRoot = targetChar:FindFirstChild("UpperTorso") 
                    or targetChar:FindFirstChild("Torso") 
                    or targetChar:FindFirstChild("HumanoidRootPart")

    if root and targetRoot then
        local stompTime = tick()
        local MAX_STOMP_DURATION = 3 -- Give up after 3s if they dont die
        
        -- Loop until dead or timeout
        while tick() - stompTime < MAX_STOMP_DURATION do
            -- Verify they are still knocked
            local ko = targetChar:FindFirstChild("BodyEffects") and targetChar.BodyEffects:FindFirstChild("K.O")
            if not ko or not ko.Value then break end -- They got up or died
            
            -- Glue Logic
            local h = STOMP_HEIGHT -- Use slider value
            local pos = targetRoot.Position + Vector3.new(0, h, 0)
            local cf = CFrame.new(pos, pos + Vector3.new(0,0,1)) -- Look generic
            
            -- 1. Physics Glue
            if sethiddenproperty then
                sethiddenproperty(root, "PhysicsRepRootPart", targetRoot)
            end
            
            -- 2. Teleport (Desync if possible, else standard)
            if api.can_desync and api:can_desync() then
                api:set_desync_cframe(cf)
            else
                root.CFrame = cf
            end
            
            -- 3. Fire Stomp
            ReplicatedStorage.MainEvent:FireServer("Stomp")
            
            RunService.Heartbeat:Wait()
        end
        
        -- Cleanup Physics
        if sethiddenproperty then
             sethiddenproperty(root, "PhysicsRepRootPart", nil) -- Reset
        end
        
        Notify("✅ Stomp attempt finished for " .. targetPlayer.Name)
    end
    
    ProcessingTarget = false
end

-- Main Loop
Notify("Auto Bounty Loaded! (Glue Stomp Enabled)")
RefreshTargets()

task.spawn(function()
    while true do
        if ENABLED and not ProcessingTarget then
            RefreshTargets() -- Refresh list periodically
            
            for name, _ in pairs(BountyTargets) do
                -- Find the player object
                local targetPlayer = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name == name or p.DisplayName == name then
                        targetPlayer = p
                        break
                    end
                end
                
                if targetPlayer and targetPlayer.Character then
                    -- Check if KNOCKED
                    local bodyEffects = targetPlayer.Character:FindFirstChild("BodyEffects")
                    local ko = bodyEffects and bodyEffects:FindFirstChild("K.O")
                    local grabbed = bodyEffects and bodyEffects:FindFirstChild("Grabbed")
                    
                    if ko and ko.Value == true then
                        -- Check if grabbed? (Optional: Ignore if Grabbed.Value ~= nil)
                        
                        -- Execute Stomp
                        StompTarget(targetPlayer)
                        break 
                    end
                end
            end
        end
        task.wait(0.5) -- Scan checking rate
    end
end)
