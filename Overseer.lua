--[[
    The Overseer - Intelligent Addon for Unnamed Cheats
    Features:
    [X] Reflex Mode: Auto-Rage when damaged.
    [Z] Smart Medic: Auto-Buy & Eat Lettuce when low health.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Configuration
local Config = {
    SmartMedic = false,
    HealThreshold = 50, -- Health % to trigger eat
}

-- State
local State = {
    IsEating = false
}

-- Drawing HUD
local HUD = {
    Text = Drawing.new("Text")
}
HUD.Text.Visible = true
HUD.Text.Color = Color3.fromRGB(255, 255, 255)
HUD.Text.Size = 18
HUD.Text.Position = Vector2.new(50, 50)
HUD.Text.Outline = true

-- Utility Functions
local function Notify(msg)
    print("[Overseer] " .. msg)
    -- Could add screen notification here
end

local function GetLettuce()
    if not LocalPlayer.Character then return nil end
    return LocalPlayer.Backpack:FindFirstChild("[Lettuce]") or LocalPlayer.Character:FindFirstChild("[Lettuce]")
end

local function BuyLettuce()
    -- Save Pos
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local oldCFrame = root.CFrame
    
    -- Teleport to Shop (Taco Shop Location needed, approx)
    -- Using generalized shop remote if possible, or manual TP
    -- Shop location roughly: 
    local ShopCFrame = CFrame.new(581, 48, -480) -- Approximation
    
    if api and api.teleport then
        api.teleport(ShopCFrame)
    else
        root.CFrame = ShopCFrame
    end
    task.wait(0.5)
    
    -- Buy (Requires finding the PurchasePrompt)
    -- This is tricky without the exact Remote path, assuming generic PurchasePrompt logic relies on clicking
    -- For now, we simulate the remote if we know it, otherwise we warn
    local prompt = Workspace:FindFirstChild("Lettuce", true) -- Search for click detector?
    if prompt and prompt:FindFirstChild("ClickDetector") then
        fireclickdetector(prompt.ClickDetector)
    else
        -- Fallback: Use Remote
        pcall(function()
             ReplicatedStorage.Remotes.PurchasePrompt:FireServer("Lettuce")
        end)
    end
    
    task.wait(0.5)
    
    -- TP Back
    if api and api.teleport then
         api.teleport(oldCFrame)
    else
         root.CFrame = oldCFrame
    end
end

-- Main Logic
local function UpdateReflex()
    if not Config.ReflexMode then return end
    
    if State.IsReflexActive then
        if tick() > State.ReflexEndTime then
             -- Turn OFF
             if api and api.flags then
                 api.flags["ragebot/enabled"] = false
                 api.flags["ragebot/silent_aim/enabled"] = false
             end
             State.IsReflexActive = false
             Notify("Reflex Deactivated.")
        else
             -- Keep ON
             if api and api.flags then
                 api.flags["ragebot/enabled"] = true
                 api.flags["ragebot/silent_aim/enabled"] = true
             end
        end
    end
end

local function UpdateMedic()
    if not Config.SmartMedic then return end
    if State.IsEating then return end
    
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if not hum then return end
    
    if hum.Health < Config.HealThreshold and hum.Health > 0 then
        State.IsEating = true
        
        local lettuce = GetLettuce()
        if lettuce then
            Notify("Eating Lettuce...")
            hum:EquipTool(lettuce)
            task.wait(0.2)
            lettuce:Activate()
            task.wait(1) -- Eat time
            hum:UnequipTools()
        else
            Notify("No Food! Restocking...")
            BuyLettuce()
        end
        
        State.IsEating = false
    end
end

local function UpdateHUD()
    local medicColor = Config.SmartMedic and "[ON]" or "[OFF]"
    
    HUD.Text.Text = string.format(
        "THE OVERSEER\n[Z] Medic: %s\nHealth: %d%%",
        medicColor,
        (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health or 0)
    )
end

-- Events
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.Z then
        Config.SmartMedic = not Config.SmartMedic
        Notify("Smart Medic: " .. tostring(Config.SmartMedic))
    end
end)

-- Main Loop
RunService.Heartbeat:Connect(function()
    UpdateHUD()
    -- Throttle Medic to not spam
    if tick() % 1 < 0.1 then
        UpdateMedic()
    end
end)

Notify("Loaded.")
