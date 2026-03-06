-- Unnamed Velocity Fling Addon (fixed, no Juju remnants)

-- local api = ... (Removed: Shadowing global API)

local players          = game:GetService("Players")
local runservice       = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local OWNER            = players.LocalPlayer

-- optional, comment out if your build doesn’t support it
-- api:set_lua_name("flingtool")

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------
local UnanchoredPart
local con, velocity_con
local Activated = false
local Active = false
local TARGET = nil
local Whitelist, OriginalVelocity = {}, {}
local Random = false
local Prediction = 0.8
local Distance = 50
local Force = Vector3.new(-10000, -10000, -10000)
local Mode = "Target"
local axes = { x = 8, y = 8, z = 8 }

---------------------------------------------------------------------
-- UTIL
---------------------------------------------------------------------
local function Notify(msg, t)
    api:notify(msg, t or 2)
end

local function Velocity(plr)
    local char = plr.Character
    if not char then return Vector3.zero end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.zero end

    local cpos = hrp.Position
    runservice.Heartbeat:Wait()
    local newPos = hrp.Position
    local dt = 1 / 60
    return (newPos - cpos) / dt
end

local function get_nearest_knocked()
    local closestPos
    local dist = Distance
    local myChar = OWNER.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, v in ipairs(players:GetPlayers()) do
        if v ~= OWNER and not table.find(Whitelist, v.Name) then
            local char = v.Character
            local bodyEffects = char and char:FindFirstChild("BodyEffects")
            local ko = bodyEffects and bodyEffects:FindFirstChild("K.O")
            local upper = char and char:FindFirstChild("UpperTorso")
            if ko and ko.Value and upper then
                local pos = upper.Position
                local mag = (pos - myRoot.Position).Magnitude
                if mag <= dist then
                    dist = mag
                    closestPos = pos
                end
            end
        end
    end

    return closestPos
end

---------------------------------------------------------------------
-- MAIN LOOP
---------------------------------------------------------------------
local function StartLoop()
    if con or not UnanchoredPart then return end
    
    -- UI Update if exists
    local t = api:get_ui_object("fling_active")
    if t and not t.Value then t:SetValue(true) end

    con = api:add_connection(runservice.Heartbeat:Connect(function()
        UnanchoredPart.CanCollide = false
        UnanchoredPart.CanTouch = false
        pcall(function()
            sethiddenproperty(OWNER, "SimulationRadius", math.huge)
            UnanchoredPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        end)

        local bp = UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") or Instance.new("BodyPosition", UnanchoredPart)
        local bt = UnanchoredPart:FindFirstChildWhichIsA("BodyThrust") or Instance.new("BodyThrust", UnanchoredPart)
        local hl = UnanchoredPart:FindFirstChildWhichIsA("Highlight") or Instance.new("Highlight", UnanchoredPart)

        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bp.P = 10000
        bp.D = 175
        bt.Force = Force

        hl.OutlineTransparency = 0
        hl.FillTransparency = 0
        local hue = tick() % 5 / 5
        local col = Color3.fromHSV(hue, 1, 1)
        hl.OutlineColor = col
        hl.FillColor = col

        local pos

        if Mode == "KO" then
            pos = get_nearest_knocked()
        elseif Mode == "Target" and Activated and TARGET and TARGET.Character and TARGET.Character:FindFirstChild("HumanoidRootPart") then
            pos = TARGET.Character.HumanoidRootPart.Position + (OriginalVelocity[1] or Vector3.zero) * Prediction
        end

        local myChar = OWNER.Character
        local upper = myChar and myChar:FindFirstChild("UpperTorso")
        if pos then
            bp.Position = pos
            bt.Location = pos
        elseif upper then
            local offset
            if Random then
                offset = Vector3.new(
                    math.random(-axes.x, axes.x),
                    math.random(-axes.y, axes.y),
                    math.random(-axes.z, axes.z)
                )
            else
                offset = Vector3.new(0, axes.y, 0)
            end
            bp.Position = upper.Position + offset
            bt.Location = upper.Position
        end
    end))
end

local function StopLoop()
    if con then
        con:Disconnect()
        con = nil
    end
    -- UI Update if exists
    local t = api:get_ui_object("fling_active")
    if t and t.Value then t:SetValue(false) end
end

---------------------------------------------------------------------
-- UI (ragebot Tab)
---------------------------------------------------------------------
local tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local group = tab:AddRightGroupbox("Velocity Fling")

group:AddToggle("fling_active", {
    Text = "Enable Fling",
    Default = false,
    Callback = function(val)
        Active = val
        if val then StartLoop() else StopLoop() end
    end
})

group:AddLabel("Keybinds: Q (Toggle), E (Target), Z (Dash)")

group:AddDropdown("fling_mode", {
    Text = "Mode",
    Default = "Target",
    Values = {"Target", "KO"},
    Callback = function(val)
        Mode = val
    end
})


---------------------------------------------------------------------
-- INPUT (Q toggle, E target, Z dash)
---------------------------------------------------------------------
api:add_connection(userInputService.InputBegan:Connect(function(input, g)
    if g then return end

    if input.KeyCode == Enum.KeyCode.Q then
        Active = not Active
        if Active then
            StartLoop()
            Notify("Velocity ON")
        else
            StopLoop()
            Notify("Velocity OFF")
        end
    end

    if input.KeyCode == Enum.KeyCode.E then
        local mouse = OWNER:GetMouse()
        local targetPlayer
        if mouse.Target then
            local model = mouse.Target:FindFirstAncestorOfClass("Model")
            if model then
                targetPlayer = players:GetPlayerFromCharacter(model)
            end
        end
        if targetPlayer then
            TARGET = targetPlayer
            Activated = true
            task.delay(0.3, function() Activated = false end)
            Notify("Target: " .. targetPlayer.Name)
        else
            Notify("No target found")
        end
    end

    if input.KeyCode == Enum.KeyCode.Z then
        local char = OWNER.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -25)
        end
    end
end))

---------------------------------------------------------------------
-- VELOCITY TRACKER
---------------------------------------------------------------------
velocity_con = api:add_connection(runservice.Heartbeat:Connect(function()
    if TARGET then
        OriginalVelocity[1] = Velocity(TARGET)
    end
end))

---------------------------------------------------------------------
-- PART FIND
---------------------------------------------------------------------
local map = workspace:FindFirstChild("MAP")
if map then
    for _, part in ipairs(map:GetChildren()) do
        if part:IsA("Part") and not part.Anchored then
            UnanchoredPart = part
            part.Transparency = 0
            Notify("Part Found")
            break
        end
    end
end
if not UnanchoredPart then
    Notify("No Part Found")
end

---------------------------------------------------------------------
-- UNLOAD
---------------------------------------------------------------------
api:on_event("unload", function()
    StopLoop()
    if velocity_con then velocity_con:Disconnect() end
    if UnanchoredPart then
        UnanchoredPart.Velocity = Vector3.zero
        UnanchoredPart.CanCollide = true
    end
    Notify("Velocity addon unloaded", 2)
end)

Notify("Velocity handler loaded (fixed api, no Juju / AddTab)", 2)
