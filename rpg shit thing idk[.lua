-- Grenade TP to Silent Aim Target
-- Unnamed API Script

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

api:set_lua_name("GrenadeTP")

-- UI Setup
local tabs = {
    grenade = api:AddTab("Grenade TP")
}

local Settings = {
    Enabled = false,
    AutoThrow = false,
    StickToTarget = true
}

-- Get target's root part
local function getRoot(target)
    if not target then return nil end
    local charCache = api:get_character_cache(target)
    if not charCache then return nil end
    return charCache.HumanoidRootPart or charCache.LowerTorso or charCache.Torso
end

-- TP grenade to target
local function tpGrenade(grenade, targetPart)
    if not grenade or not targetPart then return end
    
    local handle = grenade:FindFirstChild("Handle")
    if not handle then return end
    
    task.spawn(function()
        task.wait(0.05)
        
        local bp = Instance.new("BodyPosition")
        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bp.Position = targetPart.Position
        bp.P = 10000
        bp.D = 500
        bp.Parent = handle
        
        if Settings.StickToTarget then
            local targetCache = api:get_target_cache("silent")
            if targetCache and targetCache.player then
                local targetRoot = getRoot(targetCache.player)
                if targetRoot then
                    pcall(function()
                        sethiddenproperty(handle, "PhysicsRepRootPart", targetRoot)
                    end)
                end
            end
        end
        
        local updateConn
        updateConn = RunService.Heartbeat:Connect(function()
            if not handle or not handle.Parent then
                updateConn:Disconnect()
                if bp then bp:Destroy() end
                return
            end
            
            local currentTarget = api:get_target_cache("silent")
            if currentTarget and currentTarget.part then
                bp.Position = currentTarget.part.Position
            end
        end)
        
        task.wait(2.5)
        if updateConn then updateConn:Disconnect() end
        if bp and bp.Parent then bp:Destroy() end
    end)
end

-- Monitor for thrown grenades
local throwConnection
local function startMonitoring()
    if throwConnection then return end
    
    throwConnection = workspace.ChildAdded:Connect(function(child)
        if not Settings.Enabled then return end
        
        if child.Name == "[Grenade]" and child:IsA("Tool") then
            local targetCache = api:get_target_cache("silent")
            if targetCache and targetCache.part then
                tpGrenade(child, targetCache.part)
            end
        end
        
        if child:IsA("Part") and child.Name == "Handle" and child.Parent and child.Parent.Name == "[Grenade]" then
            local targetCache = api:get_target_cache("silent")
            if targetCache and targetCache.part then
                tpGrenade(child.Parent, targetCache.part)
            end
        end
    end)
    
    api:add_connection(throwConnection)
end

-- Throw grenade function
local lastThrow = 0
local function throwGrenade()
    if not Settings.Enabled then return end
    if tick() - lastThrow < 0.5 then return end
    
    local targetCache = api:get_target_cache("silent")
    if not targetCache or not targetCache.player then return end
    
    local grenade = LocalPlayer.Character:FindFirstChild("[Grenade]") or 
                    LocalPlayer.Backpack:FindFirstChild("[Grenade]")
    
    if not grenade then return end
    
    if grenade.Parent == LocalPlayer.Backpack then
        LocalPlayer.Character.Humanoid:EquipTool(grenade)
        task.wait(0.1)
    end
    
    grenade:Activate()
    lastThrow = tick()
end

-- UI Elements
do
    local groupbox = tabs.grenade:AddLeftGroupbox("Settings")
    
    groupbox:AddToggle("grenade_toggle", {
        Text = "Enable Grenade TP",
        Default = false,
        Callback = function(value)
            Settings.Enabled = value
            if value then
                startMonitoring()
            end
        end
    }):AddKeyPicker("grenade_keybind", {
        Text = "Grenade TP",
        Default = "None",
        Mode = "Toggle"
    })
    
    groupbox:AddToggle("stick_toggle", {
        Text = "Stick to Target",
        Default = true,
        Tooltip = "Uses PhysicsRepRootPart to stick grenade",
        Callback = function(value)
            Settings.StickToTarget = value
        end
    })
    
    groupbox:AddToggle("auto_throw", {
        Text = "Auto Throw on Target",
        Default = false,
        Tooltip = "Automatically throws grenades when you have a target",
        Callback = function(value)
            Settings.AutoThrow = value
        end
    })
    
    groupbox:AddButton({
        Text = "Manual Throw (Press V)",
        Func = function()
            throwGrenade()
        end
    })
    
    groupbox:AddLabel("Status: Waiting...")
end

-- Manual throw keybind using InputService
local UserInputService = game:GetService("UserInputService")
local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        throwGrenade()
    end
end)

api:add_connection(inputConnection)

-- Auto throw checker
local autoThrowConnection = RunService.Heartbeat:Connect(function()
    if not Settings.AutoThrow or not Settings.Enabled then return end
    
    local targetCache = api:get_target_cache("silent")
    if targetCache and targetCache.player then
        local grenade = LocalPlayer.Backpack:FindFirstChild("[Grenade]")
        if grenade and tick() - lastThrow > 1 then
            throwGrenade()
        end
    end
end)

api:add_connection(autoThrowConnection)

-- Cleanup on unload
api:on_event("unload", function()
    if throwConnection then throwConnection:Disconnect() end
    if inputConnection then inputConnection:Disconnect() end
    if autoThrowConnection then autoThrowConnection:Disconnect() end
    api:notify("Grenade TP unloaded", 2)
end)

-- Initialize
startMonitoring()
api:notify("Grenade TP loaded! Press V to throw", 2)
