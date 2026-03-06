--[[
    Unnamed Addon: Grenade Teleport
    Teleports thrown grenades directly to your target using hidden properties!
]]

api:set_lua_name("GrenadeTP")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- UI Setup
local tabs = { Combat = api:GetTab("combat") or api:AddTab("combat") }
local sec = tabs.Combat:AddRightGroupbox("Grenade Teleport")

-- UI Definitions (Safety wrapper to prevent nil errors)
local function SafeCreate(creatorFunc, ...)
    local success, result = pcall(creatorFunc, ...)
    if not success or not result then
        warn("UI Creation Failed:", result)
        return { Value = false } -- Dummy object to prevent crash
    end
    return result
end

-- Create UI Elements
local Enabled = sec:AddToggle("GTP_Enable", { Text = "Enable Grenade TP", Default = false })
local LoopTP = sec:AddToggle("GTP_Loop", { Text = "Loop Teleport (Sticky)", Default = false })
local BuyAmount = sec:AddSlider("GTP_Amount", { Text = "Buy Amount", Default = 1, Min = 1, Max = 10, Rounding = 0 })

-- Safety Checks
if not Enabled then Enabled = { Value = false } end
if not LoopTP then LoopTP = { Value = false } end
if not BuyAmount then BuyAmount = { Value = 1 } end

-- Logic
local function GetTarget()
    -- 1. Try Global Silent Aim Target (if shared by other scripts)
    if _G.SilentAimTarget and _G.SilentAimTarget.Character and _G.SilentAimTarget.Character:FindFirstChild("HumanoidRootPart") then
        return _G.SilentAimTarget
    end
    
    -- 2. Fallback: Get Closest Player to Mouse
    local closest = nil
    local maxDist = 500 -- Max mouse distance
    local mouse = LocalPlayer:GetMouse()
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    closest = p
                end
            end
        end
    end
    
    return closest
end

local function TeleportGrenade(grenade)
    if not Enabled.Value then return end
    
    local target = GetTarget()
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then 
        return 
    end
    
    local targetPart = target.Character.HumanoidRootPart
    
    -- Find the main part (Handle or Head as per user dump)
    local grenadeHandle = grenade:FindFirstChild("Handle") or grenade:FindFirstChild("Head")
    if not grenadeHandle then
        -- Wait briefly in case it's loading
        grenadeHandle = grenade:WaitForChild("Handle", 1) or grenade:WaitForChild("Head", 1)
    end
    
    if not grenadeHandle then
        -- Last resort: treat the grenade itself as the part if it's a Part/MeshPart
        if grenade:IsA("BasePart") then
            grenadeHandle = grenade
        else
            return -- valid part not found
        end
    end
    
    api:notify("Grenade TP -> " .. target.Name, 2)
    
    -- sethiddenproperty(Object, Property, Value)
    local success, err = pcall(function()
        if sethiddenproperty then
            -- Set Handle CFrame to Target CFrame
            sethiddenproperty(grenadeHandle, "CFrame", targetPart.CFrame)
            sethiddenproperty(grenadeHandle, "Velocity", Vector3.new(0,0,0)) 
            sethiddenproperty(grenadeHandle, "RotVelocity", Vector3.new(0,0,0))
            
            -- Keep it there
            if LoopTP.Value then
                task.spawn(function()
                    local startTime = tick()
                    while grenadeHandle and grenadeHandle.Parent and (tick() - startTime < 3) do
                         if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                              sethiddenproperty(grenadeHandle, "CFrame", target.Character.HumanoidRootPart.CFrame)
                              sethiddenproperty(grenadeHandle, "Velocity", Vector3.new(0,0,0))
                         end
                         task.wait()
                    end
                end)
            end
        else
            -- Fallback
            grenadeHandle.CFrame = targetPart.CFrame
        end
    end)
    
    if not success then warn("TP Error:", err) end
end

sec:AddButton({ Text = "Start Buying Grenades", Func = function()
    local amount = BuyAmount.Value
    local MainEvent = game:GetService("ReplicatedStorage"):FindFirstChild("MainEvent")
    
    if not MainEvent then 
        api:notify("Error: MainEvent not found!", 3) 
        return 
    end
    
    api:notify("Buying " .. amount .. " Grenades...", 2)
    
    for i = 1, amount do
        MainEvent:FireServer("Purchase", "Grenade")
        task.wait(0.1) -- Small cooldown to prevent output spam/throttle
    end
end })

-- Monitor Workspace for new Grenades
Workspace.ChildAdded:Connect(function(child)
    if not Enabled.Value then return end
    
    local name = child.Name:lower()
    if name:find("grenade") or name:find("flashbang") or name:find("rpg") or name == "handle" then
         task.wait(0.05)
         TeleportGrenade(child)
    end
end)
