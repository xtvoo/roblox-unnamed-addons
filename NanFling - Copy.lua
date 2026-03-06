api:set_lua_name("NaN_Fling")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local tab = api:add_tab("NaN Fling")
local group = tab:AddRightGroupbox("Controls")

local toggle_master = group:AddToggle("fling_master", {
    Text = "Master Fling Toggle",
    Default = true,
    Tooltip = "If disabled, absolutely NO flings will occur (manual or auto)",
})

local input_target = group:AddInput("fling_target_input", {
    Default = "",
    Numeric = false,
    Finished = false,
    Text = "Target Player (Manual)",
    Tooltip = "Enter partial or full name",
    Placeholder = "Player Name...",
})

local toggle_loop = group:AddToggle("fling_loop", {
    Text = "Loop Fling",
    Default = false,
    Tooltip = "Keep flinging until stopped or target leaves",
})

local toggle_silent = group:AddToggle("fling_use_silent", {
    Text = "Use Silent Aim Target",
    Default = true,
    Tooltip = "Prioritize Silent Aim target over manual input",
})

local toggle_autofling = group:AddToggle("fling_auto", {
    Text = "Auto Fling (Rage)",
    Default = false,
    Tooltip = "Continuously flings nearby players",
})

toggle_autofling:AddKeyPicker("fling_keybind", {
    Default = "K",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Auto Fling Toggle"
})

local toggle_demon = group:AddToggle("fling_demon", {
    Text = "DEMON MODE 😈",
    Default = false,
    Tooltip = "Rapid-fire flings everything! No mercy. Bypasses sit/KO checks.",
})

toggle_demon:AddKeyPicker("demon_keybind", {
    Default = "V",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Demon Mode Toggle"
})

local toggle_mouse_priority = group:AddToggle("fling_mouse_priority", {
    Text = "Target Nearest to Mouse",
    Default = true,
    Tooltip = "Prioritizes players near your cursor instead of your character",
})

local slider_rage_dist = group:AddSlider("fling_range", {
    Text = "Rage Distance",
    Default = 300,
    Min = 10,
    Max = 1500,
    Rounding = 0,
    Compact = false,
    Tooltip = "Maximum distance to detect targets for Auto Fling",
})

local isFlinging = false
local currentFlingConnection = nil
local currentTarget = nil
local visualHighlight = nil

local function UpdateVisuals(target)
    if not target then
        if visualHighlight then
            visualHighlight:Destroy()
            visualHighlight = nil
        end
        return
    end

    if not visualHighlight then
        visualHighlight = Instance.new("Highlight")
        visualHighlight.Parent = game:GetService("CoreGui")
    end

    visualHighlight.FillColor = toggle_demon.Value and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 0, 0)
    visualHighlight.OutlineColor = toggle_demon.Value and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
    visualHighlight.FillTransparency = toggle_demon.Value and 0.8 or 0.5
    visualHighlight.OutlineTransparency = 0

    if target.Character then
        visualHighlight.Adornee = target.Character
    end
end

local function GetSilentAimTarget()
    local success, cache = pcall(function() return api:get_target_cache("silent") end)
    if success and cache and cache.player then
        return cache.player
    end
    return nil
end

local function GetTarget(name)
    if toggle_silent.Value then
        local silentTarget = GetSilentAimTarget()
        if silentTarget then return silentTarget end
    end

    if not name or name == "" then return nil end

    local target = Players:FindFirstChild(name)
    if not target then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():match(name:lower()) or p.DisplayName:lower():match(name:lower()) then
                target = p
                break
            end
        end
    end
    return target
end

local function StartFling(target)
    if not toggle_master.Value then 
        api:notify("Master Fling is OFF. Fling aborted.", 2)
        return 
    end
    if isFlinging then return end
    if not target then return end

    if target == LocalPlayer then return end

    local char = LocalPlayer.Character
    local targetChar = target.Character

    if not char or not targetChar then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

    if not hrp or not hum or not targetHrp or not targetHum then return end

    local bodyEffects = targetChar:FindFirstChild("BodyEffects")
    local isKnocked = bodyEffects and bodyEffects:FindFirstChild("KO") and bodyEffects.KO.Value
    local isSitting = targetHum.Sit

    local myBodyEffects = char:FindFirstChild("BodyEffects")
    local myKnocked = myBodyEffects and myBodyEffects:FindFirstChild("KO") and myBodyEffects.KO.Value
    local mySitting = hum.Sit

    if not toggle_demon.Value and (isKnocked or isSitting) then
        api:notify("Target is knocked or sitting. Fling aborted.", 3)
        return
    end

    if not toggle_demon.Value and (myKnocked or mySitting) then
        -- Silent abort if we are the ones knocked or in a vehicle
        return
    end

    isFlinging = true
    currentTarget = target
    api:notify("Flinging " .. target.DisplayName, 3)

    local nan_vector = Vector3.new(0/0, 0/0, 0/0)
    local start_time = tick()

    hum.PlatformStand = true

    currentFlingConnection = RunService.Heartbeat:Connect(function()
        if not isFlinging or
           not LocalPlayer.Character or
           not target.Character or
           not target.Parent then
            StopFling()
            return
        end

        local t_hum = target.Character:FindFirstChildOfClass("Humanoid")
        local t_bodyEffects = target.Character:FindFirstChild("BodyEffects")
        local t_isKnocked = t_bodyEffects and t_bodyEffects:FindFirstChild("KO") and t_bodyEffects.KO.Value
        local t_isSitting = t_hum and t_hum.Sit

        local c_hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local c_bodyEffects = LocalPlayer.Character:FindFirstChild("BodyEffects")
        local c_isKnocked = c_bodyEffects and c_bodyEffects:FindFirstChild("KO") and c_bodyEffects.KO.Value
        local c_isSitting = c_hum and c_hum.Sit

        if not t_hum or t_hum.Health <= 0 or (not toggle_demon.Value and (t_isKnocked or t_isSitting)) then
            StopFling()
            return
        end

        if not c_hum or c_hum.Health <= 0 or (not toggle_demon.Value and (c_isKnocked or c_isSitting)) then
            StopFling()
            return
        end

        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end

        local timeout = toggle_demon.Value and 0.15 or 0.5
        if (tick() - start_time) >= timeout then
             StopFling()
             return
        end

        local c_hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local t_hrp = target.Character:FindFirstChild("HumanoidRootPart")

        if c_hrp and t_hrp then
            c_hrp.CFrame = t_hrp.CFrame
            c_hrp.AssemblyLinearVelocity = nan_vector
            c_hrp.AssemblyAngularVelocity = nan_vector

            pcall(function()
                sethiddenproperty(c_hrp, "PhysicsRepRootPart", t_hrp)
            end)

            if api.set_desync_cframe then
                 api:set_desync_cframe(t_hrp.CFrame)
            end

            pcall(function()
                hum:Move(nan_vector)
            end)
        end
    end)

    UpdateVisuals(target)
end

function StopFling()
    if not isFlinging then return end
    isFlinging = false
    currentTarget = nil

    if currentFlingConnection then
        currentFlingConnection:Disconnect()
        currentFlingConnection = nil
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false


        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = false
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)

            pcall(function()
                sethiddenproperty(hrp, "PhysicsRepRootPart", nil)
            end)
        end
    end
    UpdateVisuals(nil)
    api:notify("Fling stopped.", 2)
end

group:AddButton("Fling Target!", function()
    local target = GetTarget(input_target.Value)
    if target then
        StartFling(target)
    else
        api:notify("No valid target found.", 3)
    end
end)

group:AddButton("Stop Flinging", function()
    if toggle_loop.Value then
        pcall(function() toggle_loop:SetValue(false) end)
    end
    StopFling()
end)

toggle_autofling:OnChanged(function()
    if not toggle_autofling.Value and not toggle_loop.Value and not toggle_demon.Value then
        StopFling()
    end
end)

toggle_demon:OnChanged(function()
    if not toggle_demon.Value and not toggle_autofling.Value and not toggle_loop.Value then
        StopFling()
    end
end)

RunService.Heartbeat:Connect(function()
    if toggle_loop.Value and not isFlinging and not toggle_autofling.Value then
        local target = GetTarget(input_target.Value)
        if target and target.Character then
            local t_hum = target.Character:FindFirstChildOfClass("Humanoid")
            local t_bodyEffects = target.Character:FindFirstChild("BodyEffects")
            local t_isKnocked = t_bodyEffects and t_bodyEffects:FindFirstChild("KO") and t_bodyEffects.KO.Value
            local t_isSitting = t_hum and t_hum.Sit

            local isValid = toggle_demon.Value or (not t_isKnocked and not t_isSitting)
            if t_hum and t_hum.Health > 0 and isValid then
                StartFling(target)
            end
        end
    end
end)

local UserInputService = game:GetService("UserInputService")

local function GetClosestPlayerToMouse()
    local mouseLocation = UserInputService:GetMouseLocation()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local myBody = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("BodyEffects")
    local myKnocked = myBody and myBody:FindFirstChild("KO") and myBody.KO.Value
    if not myHum or (not toggle_demon.Value and (myHum.Sit or myKnocked)) then return nil end

    local bestTarget = nil
    local shortestDist = slider_rage_dist.Value

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            local bodyEffects = p.Character:FindFirstChild("BodyEffects")
            local isKnocked = bodyEffects and bodyEffects:FindFirstChild("KO") and bodyEffects.KO.Value
            local isSitting = hum and hum.Sit

            local isValidTarget = toggle_demon.Value or (not isKnocked and not isSitting)
            if hum and hum.Health > 0 and isValidTarget then
                local pos, onScreen = camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        bestTarget = p
                    end
                end
            end
        end
    end
    return bestTarget
end

local function GetClosestPlayerToCharacter()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local myBody = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("BodyEffects")
    local myKnocked = myBody and myBody:FindFirstChild("KO") and myBody.KO.Value
    if not myHum or (not toggle_demon.Value and (myHum.Sit or myKnocked)) then return nil end

    local bestTarget = nil
    local maxDist = slider_rage_dist.Value

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChild("Humanoid")
            local bodyEffects = p.Character:FindFirstChild("BodyEffects")
            local isKnocked = bodyEffects and bodyEffects:FindFirstChild("KO") and bodyEffects.KO.Value
            local isSitting = hum and hum.Sit

            local isValidTarget = toggle_demon.Value or (not isKnocked and not isSitting)
            if hum and hum.Health > 0 and isValidTarget then
                local dist = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    bestTarget = p
                end
            end
        end
    end
    return bestTarget
end

task.spawn(function()
    while true do
        task.wait(toggle_demon.Value and 0.05 or 0.5)
        if toggle_autofling.Value or toggle_demon.Value then
            local bestTarget = nil
            if toggle_mouse_priority.Value then
                bestTarget = GetClosestPlayerToMouse()
            else
                bestTarget = GetClosestPlayerToCharacter()
            end
            
            if bestTarget then
                if isFlinging and currentTarget ~= bestTarget then
                    StopFling()
                    task.wait()
                    StartFling(bestTarget)
                elseif not isFlinging then
                    StartFling(bestTarget)
                end
            end
        end
    end
end)

api:notify("NaN Fling (Keybind + Desync) Loaded", 5)
